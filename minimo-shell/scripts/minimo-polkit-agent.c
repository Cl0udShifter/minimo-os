// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS

#define POLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE 1

#include <polkitagent/polkitagent.h>
#include <gio/gio.h>
#include <gio/gunixsocketaddress.h>
#include <glib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/stat.h>

typedef struct {
    PolkitAgentListener parent_instance;
} MinimoListener;

typedef struct {
    PolkitAgentListenerClass parent_class;
} MinimoListenerClass;

G_DEFINE_TYPE(MinimoListener, minimo_listener, POLKIT_AGENT_TYPE_LISTENER);

typedef struct {
    PolkitAgentListener *listener;
    PolkitAgentSession *session;
    GTask *task;
    char *action_id;
    char *message;
    char *user_name;
    char *cookie;
    gboolean is_completed;
    GSocketService *socket_service;
    char *sock_path;
} ActiveAuth;

static ActiveAuth *current_auth = NULL;
static char *qs_path = NULL;

static void notify_quickshell(const char *cmd_target, const char *arg1, const char *arg2) {
    char *qs_bin = g_find_program_in_path("qs");
    if (!qs_bin) return;

    GPtrArray *args = g_ptr_array_new();
    g_ptr_array_add(args, qs_bin);
    if (qs_path) {
        g_ptr_array_add(args, "-p");
        g_ptr_array_add(args, qs_path);
    }
    g_ptr_array_add(args, "ipc");
    g_ptr_array_add(args, "call");
    g_ptr_array_add(args, (gpointer)cmd_target);
    if (arg1) g_ptr_array_add(args, (gpointer)arg1);
    if (arg2) g_ptr_array_add(args, (gpointer)arg2);
    g_ptr_array_add(args, NULL);

    GError *err = NULL;
    g_spawn_async(NULL, (char **)args->pdata, NULL,
                  G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL,
                  NULL, NULL, NULL, &err);
    if (err) {
        g_printerr("[minimo-polkit] Failed to invoke qs ipc: %s\n", err->message);
        g_error_free(err);
    }
    g_ptr_array_free(args, TRUE);
    g_free(qs_bin);
}

static char *escape_json_string(const char *s) {
    if (!s) return g_strdup("");
    GString *out = g_string_new("");
    for (const char *p = s; *p; p++) {
        if (*p == '"') g_string_append(out, "\\\"");
        else if (*p == '\\') g_string_append(out, "\\\\");
        else if (*p == '\n') g_string_append(out, "\\n");
        else if (*p == '\r') g_string_append(out, "\\r");
        else if (*p == '\t') g_string_append(out, "\\t");
        else g_string_append_c(out, *p);
    }
    return g_string_free(out, FALSE);
}

static void stop_socket_service(ActiveAuth *auth) {
    if (auth->socket_service) {
        g_socket_service_stop(auth->socket_service);
        g_socket_listener_close(G_SOCKET_LISTENER(auth->socket_service));
        g_clear_object(&auth->socket_service);
    }
    if (auth->sock_path) {
        unlink(auth->sock_path);
    }
}

static gboolean on_incoming_connection(GSocketService *service,
                                       GSocketConnection *connection,
                                       GObject *source_object,
                                       gpointer user_data) {
    ActiveAuth *auth = (ActiveAuth *)user_data;
    if (!auth || auth->is_completed) return TRUE;

    GInputStream *in = g_io_stream_get_input_stream(G_IO_STREAM(connection));
    GDataInputStream *data_in = g_data_input_stream_new(in);
    gsize length = 0;
    GError *err = NULL;
    char *line = g_data_input_stream_read_line(data_in, &length, NULL, &err);

    if (line) {
        // Parse simple JSON: {"action": "...", "password": "..."}
        if (strstr(line, "\"action\": \"cancel\"") || strstr(line, "\"action\":\"cancel\"")) {
            g_print("[minimo-polkit] Cancel received from UI\n");
            auth->is_completed = TRUE;
            if (auth->session) {
                polkit_agent_session_cancel(auth->session);
            }
            if (auth->task) {
                g_task_return_new_error(auth->task,
                                        POLKIT_ERROR,
                                        POLKIT_ERROR_CANCELLED,
                                        "Ação cancelada pelo usuário");
            }
            notify_quickshell("polkit", "close", NULL);
            stop_socket_service(auth);
        } else if (strstr(line, "\"action\": \"auth\"") || strstr(line, "\"action\":\"auth\"")) {
            // Extract password
            char *p1 = strstr(line, "\"password\":");
            if (p1) {
                p1 += 11;
                while (*p1 == ' ' || *p1 == '"') p1++;
                char *p2 = strrchr(p1, '"');
                if (p2 && p2 >= p1) *p2 = '\0';
                
                // Unescape \" and \\ if present
                GString *pw = g_string_new("");
                for (char *c = p1; *c; c++) {
                    if (*c == '\\' && *(c+1)) {
                        c++;
                        if (*c == 'n') g_string_append_c(pw, '\n');
                        else if (*c == 'r') g_string_append_c(pw, '\r');
                        else if (*c == 't') g_string_append_c(pw, '\t');
                        else g_string_append_c(pw, *c);
                    } else {
                        g_string_append_c(pw, *c);
                    }
                }

                g_print("[minimo-polkit] Submitting password to session...\n");
                if (auth->session) {
                    polkit_agent_session_response(auth->session, pw->str);
                }
                g_string_free(pw, TRUE);
            }
        }
        g_free(line);
    }

    g_object_unref(data_in);
    return TRUE;
}

static void start_socket_service(ActiveAuth *auth) {
    const char *runtime_dir = g_get_user_runtime_dir();
    auth->sock_path = g_build_filename(runtime_dir, "minimo-polkit.sock", NULL);
    unlink(auth->sock_path);

    GError *err = NULL;
    auth->socket_service = g_socket_service_new();
    GSocketAddress *addr = g_unix_socket_address_new(auth->sock_path);

    if (!g_socket_listener_add_address(G_SOCKET_LISTENER(auth->socket_service),
                                       addr,
                                       G_SOCKET_TYPE_STREAM,
                                       G_SOCKET_PROTOCOL_DEFAULT,
                                       NULL,
                                       NULL,
                                       &err)) {
        g_printerr("[minimo-polkit] Failed to bind socket %s: %s\n", auth->sock_path, err->message);
        g_error_free(err);
    } else {
        chmod(auth->sock_path, 0600);
        g_signal_connect(auth->socket_service, "incoming", G_CALLBACK(on_incoming_connection), auth);
        g_socket_service_start(auth->socket_service);
    }
    g_object_unref(addr);
}

static void on_request(PolkitAgentSession *session,
                       gchar *request,
                       gboolean echo_on,
                       gpointer user_data) {
    ActiveAuth *auth = (ActiveAuth *)user_data;
    g_print("[minimo-polkit] Session request: prompt='%s', echo=%d\n", request, echo_on);

    // Format JSON payload for Quickshell
    char *esc_msg = escape_json_string(auth->message);
    char *esc_act = escape_json_string(auth->action_id);
    char *esc_usr = escape_json_string(auth->user_name);

    char *json = g_strdup_printf("{\"actionId\":\"%s\",\"message\":\"%s\",\"user\":\"%s\",\"prompt\":\"%s\"}",
                                 esc_act, esc_msg, esc_usr, request ? request : "Senha:");

    notify_quickshell("polkit", "open", json);

    g_free(esc_msg);
    g_free(esc_act);
    g_free(esc_usr);
    g_free(json);
}

static void on_completed(PolkitAgentSession *session,
                         gboolean gained_authorization,
                         gpointer user_data) {
    ActiveAuth *auth = (ActiveAuth *)user_data;
    g_print("[minimo-polkit] Session completed: gained_authorization=%d\n", gained_authorization);

    if (gained_authorization) {
        auth->is_completed = TRUE;
        notify_quickshell("polkit", "success", NULL);
        if (auth->task) {
            g_task_return_boolean(auth->task, TRUE);
        }
        stop_socket_service(auth);
    } else {
        // Failed attempt: inform UI so it shakes and lets the user retry
        notify_quickshell("polkit", "error", "Senha incorreta. Tente novamente.");
        auth->is_completed = TRUE;
        if (auth->task) {
            g_task_return_boolean(auth->task, FALSE);
        }
        stop_socket_service(auth);
    }
}

static void on_show_error(PolkitAgentSession *session,
                          gchar *text,
                          gpointer user_data) {
    g_print("[minimo-polkit] Session error: %s\n", text);
    notify_quickshell("polkit", "error", text);
}

static void minimo_listener_initiate_authentication(PolkitAgentListener *listener,
                                                    const gchar *action_id,
                                                    const gchar *message,
                                                    const gchar *icon_name,
                                                    PolkitDetails *details,
                                                    const gchar *cookie,
                                                    GList *identities,
                                                    GCancellable *cancellable,
                                                    GAsyncReadyCallback callback,
                                                    gpointer user_data) {
    g_print("[minimo-polkit] Authentication requested for action: %s\n", action_id);

    ActiveAuth *auth = g_new0(ActiveAuth, 1);
    auth->listener = listener;
    auth->task = g_task_new(listener, cancellable, callback, user_data);
    auth->action_id = g_strdup(action_id);
    auth->message = g_strdup(message);
    auth->cookie = g_strdup(cookie);

    const char *user = "daniel";
    if (identities != NULL && identities->data != NULL) {
        PolkitIdentity *id = POLKIT_IDENTITY(identities->data);
        if (POLKIT_IS_UNIX_USER(id)) {
            user = polkit_unix_user_get_name(POLKIT_UNIX_USER(id));
            if (!user || strlen(user) == 0) {
                struct passwd *pw = getpwuid(polkit_unix_user_get_uid(POLKIT_UNIX_USER(id)));
                if (pw) user = pw->pw_name;
            }
        }
    }
    auth->user_name = g_strdup(user ? user : "daniel");

    current_auth = auth;

    // Start local socket to receive password response from Quickshell
    start_socket_service(auth);

    // Create session
    PolkitIdentity *identity = identities ? POLKIT_IDENTITY(identities->data) : NULL;
    auth->session = polkit_agent_session_new(identity, cookie);

    g_signal_connect(auth->session, "request", G_CALLBACK(on_request), auth);
    g_signal_connect(auth->session, "completed", G_CALLBACK(on_completed), auth);
    g_signal_connect(auth->session, "show-error", G_CALLBACK(on_show_error), auth);

    polkit_agent_session_initiate(auth->session);
}

static gboolean minimo_listener_initiate_authentication_finish(PolkitAgentListener *listener,
                                                               GAsyncResult *res,
                                                               GError **error) {
    return g_task_propagate_boolean(G_TASK(res), error);
}

static void minimo_listener_class_init(MinimoListenerClass *klass) {
    PolkitAgentListenerClass *parent_class = POLKIT_AGENT_LISTENER_CLASS(klass);
    parent_class->initiate_authentication = minimo_listener_initiate_authentication;
    parent_class->initiate_authentication_finish = minimo_listener_initiate_authentication_finish;
}

static void minimo_listener_init(MinimoListener *listener) {}

int main(int argc, char *argv[]) {
    // Resolve quickshell config path
    const char *home = g_get_home_dir();
    qs_path = g_build_filename(home, "Projetos", "minimo-os", "minimo-shell", NULL);

    GMainLoop *loop = g_main_loop_new(NULL, FALSE);
    MinimoListener *listener = g_object_new(minimo_listener_get_type(), NULL);

    GError *error = NULL;
    PolkitSubject *subject = polkit_unix_session_new_for_process_sync(0, NULL, &error);
    if (!subject) {
        g_printerr("[minimo-polkit] Failed to get subject: %s\n", error ? error->message : "unknown");
        return 1;
    }

    gpointer handle = polkit_agent_listener_register(POLKIT_AGENT_LISTENER(listener),
                                                     POLKIT_AGENT_REGISTER_FLAGS_NONE,
                                                     subject,
                                                     "/org/minimo/PolicyKit1/AuthenticationAgent",
                                                     NULL,
                                                     &error);
    if (!handle) {
        g_printerr("[minimo-polkit] Failed to register agent: %s\n", error ? error->message : "unknown");
        return 1;
    }

    g_print("[minimo-polkit] Minimo OS Polkit Agent initialized and registered successfully.\n");
    g_main_loop_run(loop);

    polkit_agent_listener_unregister(handle);
    g_object_unref(listener);
    g_main_loop_unref(loop);
    g_free(qs_path);
    return 0;
}

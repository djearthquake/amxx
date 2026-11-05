#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <cstring>
#include <sstream>
#include <cstdlib>
#include <algorithm>

#ifdef _WIN32
    #include <windows.h>
    const std::string CACHE_FILE = ".amxx_pipe_cache";
    const std::string SSH_BINARY = "ssh.exe";
    const char PATH_SEP = '/';
#else
    #include <unistd.h>
    #include <readline/readline.h> 
    #include <readline/history.h>
    const std::string CACHE_FILE = ".amxx_pipe_cache";
    const std::string SSH_BINARY = "ssh";
    const std::string PRIVATE_KEY_PATH = "~/.ssh/id_ed25519"; 
    const char PATH_SEP = '/';
#endif

struct Config {
    std::string ip = "127.0.0.1";              
    std::string user = "server_user";          
    std::string screen_name = "hlds_session";  
    std::string log_dir = "/path/to/hlds";     
    std::string log_file = "console.log";      
};

void trim_cr(std::string& str) {
    str.erase(std::remove(str.begin(), str.end(), '\r'), str.end());
    str.erase(std::remove(str.begin(), str.end(), '\n'), str.end());
}

void save_cache(const Config& cfg) {
    std::ofstream f(CACHE_FILE, std::ios::binary);
    if (f.is_open()) f << cfg.ip << "\n" << cfg.user << "\n" << cfg.screen_name << "\n" << cfg.log_dir << "\n" << cfg.log_file << "\n";
}

Config load_cache() {
    Config cfg; std::ifstream f(CACHE_FILE, std::ios::binary);
    if (f.is_open()) {
        std::getline(f, cfg.ip); trim_cr(cfg.ip); std::getline(f, cfg.user); trim_cr(cfg.user);
        std::getline(f, cfg.screen_name); trim_cr(cfg.screen_name); std::getline(f, cfg.log_dir); trim_cr(cfg.log_dir);
        std::getline(f, cfg.log_file); trim_cr(cfg.log_file);
    }
    return cfg;
}

std::string escape_quotes(const std::string& input) {
    std::string result;
    for (char c : input) { if (c == '\'') result += "'\\''"; else result += c; }
    return result;
}

void perform_c64_screen_reset() {
    std::cout << "\033[2J\033[H\033[1;44;33m**** COMMODORE 64 BASIC V2 ****\033[0m\n\033[1;44;36m64K RAM SYSTEM  38911 BASIC BYTES FREE\033[0m\n\n";
}

void play_sound_chime(bool success) {
    #ifdef _WIN32
        if (success) Beep(440, 150); else Beep(220, 300);
    #else
        if (success) std::system("speaker-test -t sine -f 440 -l 1 >/dev/null 2>&1 & (sleep 0.12 && killall speaker-test >/dev/null 2>&1) &");
        else std::system("speaker-test -t sine -f 220 -l 1 >/dev/null 2>&1 & (sleep 0.25 && killall speaker-test >/dev/null 2>&1) &");
    #endif
}

void play_retro_raster_bar() {
    std::vector<std::string> colors = {"\033[44;36m", "\033[44;37m", "\033[45;33m", "\033[40;32m", "\033[44;33m"}; 
    std::cout << "\r" << std::flush;
    for (int sweep = 0; sweep < 2; ++sweep) {
        for (const auto& color : colors) {
            std::cout << color << " [ LOADING STREAM DATA ] ===================================== " << "\033[0m\r" << std::flush;
#ifdef _WIN32
            Sleep(35);
#else
            usleep(35000);
#endif
        }
    }
    std::cout << "\033[0m\n";
}

int main() {
    Config cfg = load_cache(); std::string input; int window_lines = 45; 
    #ifdef _WIN32
        HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE); DWORD dwMode = 0;
        if (hOut != INVALID_HANDLE_VALUE && GetConsoleMode(hOut, &dwMode)) SetConsoleMode(hOut, dwMode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    #endif

    perform_c64_screen_reset();
    std::cout << "Enter Server IP [" << cfg.ip << "] : "; std::getline(std::cin, input); if (!input.empty()) cfg.ip = input;
    std::cout << "Enter Server User [" << cfg.user << "] : "; std::getline(std::cin, input); if (!input.empty()) cfg.user = input;
    std::cout << "Enter Session Name ($MOD) [" << cfg.screen_name << "] : "; std::getline(std::cin, input); if (!input.empty()) cfg.screen_name = input;
    std::cout << "Enter Log Directory [" << cfg.log_dir << "] : "; std::getline(std::cin, input); if (!input.empty()) cfg.log_dir = input;
    std::cout << "Enter Log File [" << cfg.log_file << "] : "; std::getline(std::cin, input); if (!input.empty()) cfg.log_file = input;
    save_cache(cfg);

#ifdef _WIN32
    std::string key = (GetProcAddress(GetModuleHandleA("ntdll.dll"), "wine_get_version") != NULL) 
        ? "/home/user/.ssh/id_ed25519" 
        : std::string(std::getenv("USERPROFILE") ? std::getenv("USERPROFILE") : ".") + "\\.ssh\\id_ed25519";
#else
    std::string key = PRIVATE_KEY_PATH;
#endif

    std::string base_flags = " -i \"" + key + "\" -o ControlMaster=auto -o ControlPath=\".ssh_mux_%h_%p_%r\" -o ControlPersist=10m ";

    // Immediate flush mapping optimization
    std::stringstream flush_setup; flush_setup << SSH_BINARY << base_flags << cfg.user << "@" << cfg.ip << " \"screen -S " << cfg.screen_name << " -X logfile flush 0\" >/dev/null 2>&1"; std::system(flush_setup.str().c_str());

    perform_c64_screen_reset(); std::cout << "\033[1;32mSecure Multiplex Shell Active.\033[0m Use UP/DOWN arrows for history.\n" << std::endl;

    while (true) {
        std::string command;
        #ifdef _WIN32
            std::cout << "\033[1;36mhlds_screen_relay>\033[0m "; std::getline(std::cin, command);
        #else
            rl_bind_key('\t', rl_insert); char* line = readline("\033[1;36mhlds_screen_relay>\033[0m ");
            if (!line) break; command = std::string(line); free(line); if (!command.empty()) add_history(command.c_str());
        #endif

        if (command == "exit" || command == "quit") break;
        if (command.empty()) continue;

        if (command == "clear" || command == "cls") { perform_c64_screen_reset(); continue; }
        if (command == "+") { window_lines += 5; std::cout << ">> Window grew to " << window_lines << " lines.\n"; continue; }
        if (command == "-") { if (window_lines > 5) window_lines -= 5; std::cout << ">> Window shrunk to " << window_lines << " lines.\n"; continue; }

        if (command == "relay") {
            std::cout << "\033[1;44;33m==== ENTERING LIVE RETRO STREAM MODE (Press Ctrl+C to drop back) ====\033[0m\n";
            std::stringstream stream_cmd; stream_cmd << SSH_BINARY << base_flags << cfg.user << "@" << cfg.ip << " \"tail -f -n " << window_lines << " " << cfg.log_dir << PATH_SEP << cfg.log_file << "\"";
            std::system(stream_cmd.str().c_str());
            std::cout << "\n\033[1;44;37m==== STREAM TERMINATED: DROPPING BACK TO CORE CONSOLE ==== \033[0m\n";
            continue;
        }

        std::stringstream ssh_cmd;
        ssh_cmd << SSH_BINARY << base_flags << cfg.user << "@" << cfg.ip << " \"screen -S " << cfg.screen_name << " -X eval \\\"stuff '" << escape_quotes(command) << "'\\\" \\\"stuff \\\\015\\\"\" 2>/dev/null";
        
        if (std::system(ssh_cmd.str().c_str()) == 0) {
            play_retro_raster_bar(); play_sound_chime(true); int current_view_size = window_lines;
            while (true) {
                std::cout << "\033[1;44;37m------------------ SERVER LOG RESPONSE [ -" << current_view_size << " lines ] ------------------\033[0m\n";
                std::stringstream fetch_cmd; fetch_cmd << SSH_BINARY << base_flags << cfg.user << "@" << cfg.ip << " \"tail -n " << current_view_size << " " << cfg.log_dir << PATH_SEP << cfg.log_file << " | grep -v 'AMXX-PIPE-SYNC-DONE'\" 2>/dev/null";
                std::system(fetch_cmd.str().c_str());
                std::cout << "\033[1;44;33m=================================================================================\033[0m\n";
                std::cout << "\033[1;36m[ SPACE + ENTER ]: Expand view  |  [ ENTER ]: Accept snapshot & return to prompt\033[0m\n";
                
                std::string page_input;
#ifdef _WIN32
                std::getline(std::cin, page_input);
#else
                char* page_line = readline(""); 
                page_input = (page_line) ? std::string(page_line) : ""; 
                if (page_line) free(page_line);
#endif
                if (page_input == " ") { current_view_size += window_lines; continue; } else break;
            }
        } else {
            play_sound_chime(false); std::cerr << "\033[1;31m[Error: Multiplex secure pathway failed to deliver payload.]\033[0m\n";
        }
    }

    std::stringstream flush_restore; flush_restore << SSH_BINARY << base_flags << cfg.user << "@" << cfg.ip << " \"screen -S " << cfg.screen_name << " -X logfile flush 10\" >/dev/null 2>&1"; std::system(flush_restore.str().c_str());
    std::stringstream exit_mux; exit_mux << SSH_BINARY << base_flags << "-O exit " << cfg.user << "@" << cfg.ip << " 2>/dev/null"; std::system(exit_mux.str().c_str());
    return 0;
}

/* ================================================================
   SMART IT TECHNICAL SUPPORT EXPERT SYSTEM
   Language  : SWI-Prolog
   Method    : Backward Chaining + MYCIN-style Certainty Factors
   Author    : Smart IT Expert System v1.0
   Run with  : swipl -g run expert_system.pl
   ================================================================ */

:- use_module(library(lists)).

/* ----------------------------------------------------------------
   WORKING MEMORY  (all dynamic — reset each session)
   ---------------------------------------------------------------- */
:- dynamic fact/2.        % fact(Symptom, yes|no|unknown)
:- dynamic asked/1.       % asked(Symptom)  — prevent re-asking
:- dynamic session_log/1. % audit trail

/* ================================================================
   CERTAINTY-FACTOR ENGINE  (MYCIN arithmetic)
   CF values in [-1.0 .. 1.0]
   Threshold: diagnoses below 0.30 are suppressed
   ================================================================ */

combine_cf(CF1, CF2, CF) :-
    ( CF1 >= 0, CF2 >= 0
    -> CF is CF1 + CF2 * (1 - CF1)
    ; CF1 < 0, CF2 < 0
    -> CF is CF1 + CF2 * (1 + CF1)
    ; Denom is 1 - min(abs(CF1), abs(CF2)),
      ( Denom =:= 0 -> CF = 0 ; CF is (CF1 + CF2) / Denom )
    ).

cf_threshold(0.30).

/* ================================================================
   KNOWLEDGE BASE
   Each diagnosis/2 rule fires check/4 for its key symptoms.
   check/4 either retrieves a stored fact or asks the user.
   CF is positive when the symptom is present, negative when absent.
   ================================================================ */

/* ---------------------------------------------------------------
   CATEGORY 1 — NETWORK & CONNECTIVITY
   --------------------------------------------------------------- */

%% No Internet
diagnosis(no_internet, CF) :-
    check(ping_ip_fails,   yes, 0.90, C1),
    check(no_dhcp_address, yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% DNS Failure
diagnosis(dns_failure, CF) :-
    check(ping_ip_fails,   no,  0.80, C1),
    check(ping_name_fails, yes, 0.90, C2),
    combine_cf(C1, C2, CF).

%% Slow Network
diagnosis(slow_network, CF) :-
    check(internet_slow,       yes, 0.80, C1),
    check(high_bandwidth_apps, yes, 0.65, C2),
    combine_cf(C1, C2, CF).

%% Wi-Fi Won't Connect
diagnosis(wifi_problem, CF) :-
    check(wifi_not_connecting, yes, 0.85, C1),
    check(ethernet_works,      yes, 0.75, C2),
    combine_cf(C1, C2, CF).

%% Network Adapter Missing / Error
diagnosis(network_adapter_issue, CF) :-
    check(adapter_error_devmgr, yes, 0.90, C1),
    check(ping_ip_fails,        yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% VPN Connectivity Problem
diagnosis(vpn_problem, CF) :-
    check(vpn_fails_to_connect, yes, 0.85, C1),
    check(internet_works_no_vpn,yes, 0.80, C2),
    combine_cf(C1, C2, CF).

/* ---------------------------------------------------------------
   CATEGORY 2 — OPERATING SYSTEM
   --------------------------------------------------------------- */

%% Boot Failure
diagnosis(boot_failure, CF) :-
    check(os_wont_boot,  yes, 0.95, C1),
    check(bios_posts_ok, yes, 0.60, C2),
    combine_cf(C1, C2, CF).

%% Blue Screen (BSOD)
diagnosis(bsod, CF) :-
    check(blue_screen_appears,   yes, 0.95, C1),
    check(system_reboots_itself, yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% System Freeze / Hang
diagnosis(system_freeze, CF) :-
    check(system_freezes,  yes, 0.85, C1),
    check(high_cpu_usage,  yes, 0.60, C2),
    combine_cf(C1, C2, CF).

%% Slow Performance
diagnosis(slow_performance, CF) :-
    check(computer_slow,    yes, 0.80, C1),
    check(high_disk_usage,  yes, 0.65, C2),
    combine_cf(C1, C2, CF).

%% Windows Update Failure
diagnosis(update_failure, CF) :-
    check(updates_fail,        yes, 0.90, C1),
    check(update_error_code,   yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% Profile Corruption
diagnosis(profile_corruption, CF) :-
    check(settings_reset_on_login, yes, 0.85, C1),
    check(temp_profile_warning,    yes, 0.90, C2),
    combine_cf(C1, C2, CF).

/* ---------------------------------------------------------------
   CATEGORY 3 — HARDWARE
   --------------------------------------------------------------- */

%% Hard Drive Failure
diagnosis(hdd_failure, CF) :-
    check(hdd_clicking_noise, yes, 0.90, C1),
    check(disk_read_errors,   yes, 0.85, C2),
    combine_cf(C1, C2, CF).

%% RAM Failure
diagnosis(ram_failure, CF) :-
    check(random_crashes,  yes, 0.80, C1),
    check(memory_dump_err, yes, 0.85, C2),
    combine_cf(C1, C2, CF).

%% Overheating
diagnosis(overheating, CF) :-
    check(high_temps,        yes, 0.90, C1),
    check(throttles_or_shuts,yes, 0.80, C2),
    combine_cf(C1, C2, CF).

%% PSU / Power Failure
diagnosis(psu_failure, CF) :-
    check(no_power_at_all,    yes, 0.75, C1),
    check(random_power_off,   yes, 0.75, C2),
    combine_cf(C1, C2, CF).

%% Display / GPU Problem
diagnosis(display_problem, CF) :-
    check(no_display_output,  yes, 0.85, C1),
    check(screen_artifacts,   yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% USB Device Not Recognised
diagnosis(usb_issue, CF) :-
    check(usb_not_detected,   yes, 0.85, C1),
    check(device_works_elsewhere, yes, 0.70, C2),
    combine_cf(C1, C2, CF).

/* ---------------------------------------------------------------
   CATEGORY 4 — SOFTWARE & APPLICATIONS
   --------------------------------------------------------------- */

%% Application Crash
diagnosis(app_crash, CF) :-
    check(specific_app_crashes, yes, 0.85, C1),
    check(crash_on_launch,      yes, 0.65, C2),
    combine_cf(C1, C2, CF).

%% Driver Conflict
diagnosis(driver_conflict, CF) :-
    check(device_stopped_working, yes, 0.80, C1),
    check(yellow_bang_devmgr,     yes, 0.90, C2),
    combine_cf(C1, C2, CF).

%% Disk Full
diagnosis(disk_full, CF) :-
    check(disk_nearly_full,   yes, 0.90, C1),
    check(cant_save_files,    yes, 0.80, C2),
    combine_cf(C1, C2, CF).

%% Missing DLL / Runtime Error
diagnosis(missing_runtime, CF) :-
    check(dll_not_found_error, yes, 0.90, C1),
    check(app_worked_before,   yes, 0.65, C2),
    combine_cf(C1, C2, CF).

/* ---------------------------------------------------------------
   CATEGORY 5 — SECURITY
   --------------------------------------------------------------- */

%% Malware / Virus
diagnosis(malware, CF) :-
    check(suspicious_popups,   yes, 0.80, C1),
    check(antivirus_alert,     yes, 0.85, C2),
    combine_cf(C1, C2, CF).

%% Ransomware
diagnosis(ransomware, CF) :-
    check(files_encrypted,     yes, 0.95, C1),
    check(ransom_note_found,   yes, 0.99, C2),
    combine_cf(C1, C2, CF).

%% Account Lockout
diagnosis(account_lockout, CF) :-
    check(cant_login,          yes, 0.85, C1),
    check(lockout_msg_shown,   yes, 0.90, C2),
    combine_cf(C1, C2, CF).

%% Phishing / Compromised Account
diagnosis(account_compromise, CF) :-
    check(unexpected_sent_mail, yes, 0.80, C1),
    check(unknown_login_alerts,yes, 0.85, C2),
    combine_cf(C1, C2, CF).

%% Firewall Blocking
diagnosis(firewall_blocking, CF) :-
    check(app_blocked_firewall, yes, 0.85, C1),
    check(connection_timeout,   yes, 0.60, C2),
    combine_cf(C1, C2, CF).

/* ---------------------------------------------------------------
   CATEGORY 6 — PRINTERS
   --------------------------------------------------------------- */

%% Printer Offline / Not Printing
diagnosis(printer_offline, CF) :-
    check(printer_shows_offline, yes, 0.80, C1),
    check(print_queue_stuck,     yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% Printer Driver Problem
diagnosis(printer_driver, CF) :-
    check(printer_driver_error,  yes, 0.85, C1),
    check(reinstall_fixed_it,    no,  0.55, C2),
    combine_cf(C1, C2, CF).

/* ---------------------------------------------------------------
   CATEGORY 7 — EMAIL & COMMUNICATION
   --------------------------------------------------------------- */

%% Email Not Sending
diagnosis(email_send_fail, CF) :-
    check(emails_stuck_outbox, yes, 0.85, C1),
    check(smtp_error_shown,    yes, 0.75, C2),
    combine_cf(C1, C2, CF).

%% Cannot Receive Email
diagnosis(email_recv_fail, CF) :-
    check(no_incoming_email,   yes, 0.80, C1),
    check(mailbox_quota_full,  yes, 0.70, C2),
    combine_cf(C1, C2, CF).

%% Teams / Zoom Audio-Video Issue
diagnosis(av_comms_issue, CF) :-
    check(mic_or_cam_not_working, yes, 0.85, C1),
    check(works_in_other_apps,    no,  0.65, C2),
    combine_cf(C1, C2, CF).

/* ================================================================
   SOLUTIONS  — step-by-step fix for each diagnosis
   ================================================================ */

solution(no_internet, [
  "STEP 1 | ipconfig /all — check you have a valid IP (not 169.x.x.x)",
  "STEP 2 | ping 8.8.8.8  — test raw IP reachability",
  "STEP 3 | Restart router/modem: unplug 30 sec, plug back in",
  "STEP 4 | ipconfig /release  then  ipconfig /renew",
  "STEP 5 | ipconfig /flushdns",
  "STEP 6 | netsh int ip reset  then  netsh winsock reset",
  "STEP 7 | Check physical cable or Wi-Fi signal strength",
  "STEP 8 | Try another device on same network to isolate fault"
]).

solution(dns_failure, [
  "STEP 1 | ping 8.8.8.8 to confirm IP works but name resolution fails",
  "STEP 2 | ipconfig /flushdns",
  "STEP 3 | Change DNS to Google: 8.8.8.8 / 8.8.4.4",
  "         (Settings > Network > Adapter > IPv4 > Manual DNS)",
  "STEP 4 | nslookup google.com 8.8.8.8  — test alternate DNS",
  "STEP 5 | Check hosts file for rogue entries: %SystemRoot%\\system32\\drivers\\etc\\hosts",
  "STEP 6 | Disable third-party VPN or proxy temporarily"
]).

solution(slow_network, [
  "STEP 1 | Run speedtest at fast.com or speedtest.net",
  "STEP 2 | Task Manager > Performance > Ethernet/Wi-Fi — check utilisation",
  "STEP 3 | Identify bandwidth-heavy apps (Teams HD video, OneDrive, Windows Update)",
  "STEP 4 | Limit background app bandwidth in Settings > Windows Update > Delivery Optimisation",
  "STEP 5 | Switch from Wi-Fi to Ethernet for reliable throughput",
  "STEP 6 | Change router Wi-Fi channel (use Wi-Fi Analyser app to find least congested)",
  "STEP 7 | Update network adapter drivers",
  "STEP 8 | Contact ISP if problem persists — check for line fault"
]).

solution(wifi_problem, [
  "STEP 1 | Forget Wi-Fi network and reconnect (enter password again)",
  "STEP 2 | Disable then re-enable Wi-Fi adapter in Device Manager",
  "STEP 3 | netsh wlan show profiles  — check profile list",
  "STEP 4 | netsh wlan delete profile name=\"YOUR_SSID\"  — remove corrupt profile",
  "STEP 5 | Check router: try 2.4 GHz band instead of 5 GHz for range",
  "STEP 6 | Update wireless adapter driver from manufacturer site",
  "STEP 7 | Temporarily disable VPN — some VPNs break Wi-Fi auth",
  "STEP 8 | Reset network settings: netsh int ip reset && netsh winsock reset"
]).

solution(network_adapter_issue, [
  "STEP 1 | devmgmt.msc > Network Adapters — look for yellow ! or ?",
  "STEP 2 | Right-click adapter > Update driver > Search automatically",
  "STEP 3 | If driver update fails — download manually from manufacturer",
  "STEP 4 | Uninstall adapter, then Action > Scan for hardware changes",
  "STEP 5 | Check BIOS to ensure NIC is not disabled",
  "STEP 6 | Try a USB-to-Ethernet adapter to isolate hardware fault"
]).

solution(vpn_problem, [
  "STEP 1 | Confirm internet works without VPN first",
  "STEP 2 | Re-enter VPN credentials (password may have changed)",
  "STEP 3 | Try different VPN protocol: OpenVPN, IKEv2, WireGuard",
  "STEP 4 | Check VPN server status with your provider",
  "STEP 5 | Disable firewall temporarily to test if it blocks VPN port",
  "STEP 6 | Reinstall VPN client software",
  "STEP 7 | Check if NAT-T is enabled on router for IPsec VPNs (UDP 4500)"
]).

solution(boot_failure, [
  "STEP 1 | Boot from Windows USB/DVD install media",
  "STEP 2 | Choose 'Repair your computer' > Troubleshoot > Startup Repair",
  "STEP 3 | If Startup Repair fails, open Command Prompt and run:",
  "         bootrec /fixmbr",
  "         bootrec /fixboot",
  "         bootrec /scanos",
  "         bootrec /rebuildbcd",
  "STEP 4 | Try System Restore to a previous restore point",
  "STEP 5 | sfc /scannow  from recovery Command Prompt",
  "STEP 6 | DISM /Image:C:\\ /Cleanup-Image /RestoreHealth",
  "STEP 7 | Check hard drive health: chkdsk C: /f /r from recovery",
  "STEP 8 | Last resort: Reset This PC (keep files option available)"
]).

solution(bsod, [
  "STEP 1 | Note the STOP code (e.g. IRQL_NOT_LESS_OR_EQUAL, PAGE_FAULT...)",
  "STEP 2 | Search the exact STOP code on docs.microsoft.com",
  "STEP 3 | Boot Safe Mode: hold Shift > Restart > Troubleshoot > Startup Settings",
  "STEP 4 | Event Viewer > Windows Logs > System — look for Critical errors",
  "STEP 5 | sfc /scannow  (run as Administrator)",
  "STEP 6 | DISM /Online /Cleanup-Image /RestoreHealth",
  "STEP 7 | Roll back any recently installed driver (Device Manager > Properties > Roll Back)",
  "STEP 8 | Test RAM: mdsched.exe — run overnight extended test",
  "STEP 9 | chkdsk /f /r  to check disk integrity",
  "STEP 10| If GPU-related code: use DDU to clean-uninstall GPU driver, reinstall fresh"
]).

solution(system_freeze, [
  "STEP 1 | Open Task Manager (Ctrl+Shift+Esc) — note CPU/RAM/Disk at time of freeze",
  "STEP 2 | Disable startup programs: Task Manager > Startup tab",
  "STEP 3 | Check Event Viewer > System for Kernel-Power event 41 (unexpected reboot)",
  "STEP 4 | sfc /scannow  to repair corrupted system files",
  "STEP 5 | chkdsk C: /f  (schedule for next boot)",
  "STEP 6 | Test RAM with mdsched.exe",
  "STEP 7 | Update chipset, GPU, and storage controller drivers",
  "STEP 8 | Scan for malware: Windows Defender full scan + Malwarebytes",
  "STEP 9 | Check CPU/GPU temperatures with HWiNFO64 — clean dust if hot"
]).

solution(slow_performance, [
  "STEP 1 | Task Manager > check CPU, RAM, Disk, GPU columns for bottleneck",
  "STEP 2 | Disable startup apps: Task Manager > Startup > disable high-impact items",
  "STEP 3 | Run Disk Cleanup: cleanmgr.exe > tick 'Clean up system files'",
  "STEP 4 | Settings > Storage > Storage Sense — enable and run now",
  "STEP 5 | Uninstall unused programs via Apps & Features",
  "STEP 6 | Adjust visual effects: sysdm.cpl > Advanced > Performance > Adjust for best perf",
  "STEP 7 | Set power plan to High Performance (Control Panel > Power Options)",
  "STEP 8 | Ensure at least 15% free space on C: drive",
  "STEP 9 | If HDD — defrag: defrag C: /U /V  (skip if SSD)",
  "STEP 10| Hardware upgrade path: add RAM or replace HDD with SSD"
]).

solution(update_failure, [
  "STEP 1 | Note the exact error code (e.g. 0x80070057, 0x800705B4)",
  "STEP 2 | Run Windows Update Troubleshooter: Settings > System > Troubleshoot",
  "STEP 3 | Stop update services and clear cache:",
  "         net stop wuauserv  &&  net stop bits  &&  net stop cryptSvc",
  "         ren %SystemRoot%\\SoftwareDistribution SoftwareDistribution.old",
  "         net start wuauserv  &&  net start bits  &&  net start cryptSvc",
  "STEP 4 | sfc /scannow  then retry updates",
  "STEP 5 | DISM /Online /Cleanup-Image /RestoreHealth  then retry",
  "STEP 6 | Manually download update from Microsoft Update Catalog (catalog.update.microsoft.com)",
  "STEP 7 | Check disk space — updates need several GB free"
]).

solution(profile_corruption, [
  "STEP 1 | Log off and log back in — check if temporary profile persists",
  "STEP 2 | Check Event Viewer for 'User Profile Service' errors (Event ID 1509, 1511)",
  "STEP 3 | Boot Safe Mode and log in — if OK, profile is corrupt in normal mode",
  "STEP 4 | Create a new local admin account, copy documents/desktop from old profile",
  "STEP 5 | Rename C:\\Users\\OldProfile and create fresh profile",
  "STEP 6 | Regedit: HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList",
  "         Delete or rename the .bak entry for the affected user",
  "STEP 7 | Run: sfc /scannow after profile fix"
]).

solution(hdd_failure, [
  "*** WARNING: BACK UP ALL DATA IMMEDIATELY BEFORE ANYTHING ELSE ***",
  "STEP 1 | wmic diskdrive get status  — check if 'OK' or 'Pred Fail'",
  "STEP 2 | Download CrystalDiskInfo — check SMART attributes (red = critical)",
  "STEP 3 | chkdsk C: /f /r  (schedule on reboot — will run at startup)",
  "STEP 4 | Clone failing drive to new drive using Clonezilla or Macrium Reflect",
  "STEP 5 | Replace the failing drive immediately",
  "STEP 6 | After replacement: reinstall OS or restore from backup/clone",
  "STEP 7 | Check SATA / power cables — sometimes loose cables mimic failure"
]).

solution(ram_failure, [
  "STEP 1 | Run Windows Memory Diagnostic: mdsched.exe > Restart now",
  "STEP 2 | For thorough test: create MemTest86 bootable USB and run overnight",
  "STEP 3 | Power off, reseat all RAM modules (remove, clean contacts, reinsert)",
  "STEP 4 | Test one stick at a time in slot A2 to isolate bad module",
  "STEP 5 | Check motherboard QVL (Qualified Vendor List) for RAM compatibility",
  "STEP 6 | Inspect slots for bent/damaged pins",
  "STEP 7 | Replace confirmed-faulty stick — match speed, voltage, and CAS latency"
]).

solution(overheating, [
  "STEP 1 | Install HWiNFO64 or HWMonitor and monitor temps under load",
  "         Safe max: CPU < 85°C, GPU < 90°C, SSD < 70°C",
  "STEP 2 | Open case or laptop — remove all dust with compressed air",
  "STEP 3 | Check all fans spin: CPU cooler, case fans, GPU fans",
  "STEP 4 | Replace dried thermal paste on CPU (and GPU die if confident)",
  "STEP 5 | Desktop: add case fans — front intake, rear/top exhaust",
  "STEP 6 | Laptop: use cooling pad, ensure vents not blocked",
  "STEP 7 | Check BIOS fan curves — increase fan speed thresholds",
  "STEP 8 | Consider aftermarket CPU cooler for desktop builds"
]).

solution(psu_failure, [
  "STEP 1 | Test with a known-good PSU if available",
  "STEP 2 | Use PSU tester (paperclip test for rough check: short green + black on 24-pin)",
  "STEP 3 | Reduce load: remove GPU and extra drives, test with bare minimum",
  "STEP 4 | Check all power cables firmly seated (24-pin, 8-pin CPU, PCIe)",
  "STEP 5 | Inspect for blown capacitors, burn marks, or unusual smell",
  "STEP 6 | Check wall outlet and surge protector functionality",
  "STEP 7 | Calculate wattage: use PSU calculator at outervision.com",
  "STEP 8 | Replace PSU — do NOT attempt internal repair"
]).

solution(display_problem, [
  "STEP 1 | Check cable connections at both monitor and PC ends",
  "STEP 2 | Try a different cable (HDMI/DisplayPort/DVI)",
  "STEP 3 | Try the monitor on a different device to isolate monitor vs PC",
  "STEP 4 | Check monitor is set to correct input source (HDMI 1, DP, etc.)",
  "STEP 5 | Reseat the GPU in its PCIe slot (after powering off fully)",
  "STEP 6 | If PC has integrated graphics: remove GPU and test with iGPU",
  "STEP 7 | Boot to BIOS — if display works in BIOS, issue is OS/driver level",
  "STEP 8 | Boot Safe Mode, uninstall GPU driver, reinstall fresh from manufacturer"
]).

solution(usb_issue, [
  "STEP 1 | Try the device in a different USB port (rear ports are more reliable)",
  "STEP 2 | Try on another computer to confirm device itself works",
  "STEP 3 | Device Manager > check for Unknown Device entries",
  "STEP 4 | Uninstall Universal Serial Bus Controllers entries, then Scan for changes",
  "STEP 5 | Disable USB Selective Suspend: Power Options > Advanced > USB Settings",
  "STEP 6 | Update chipset / USB controller drivers",
  "STEP 7 | Check USB port power: some ports supply less current (especially front-panel)"
]).

solution(app_crash, [
  "STEP 1 | Event Viewer > Windows Logs > Application — find error matching app name",
  "STEP 2 | Run the app as Administrator (right-click > Run as administrator)",
  "STEP 3 | Uninstall and reinstall the application cleanly",
  "STEP 4 | Install latest Visual C++ Redistributables from Microsoft",
  "STEP 5 | Install .NET Framework versions required by the app",
  "STEP 6 | Disable antivirus/real-time protection temporarily to check for conflict",
  "STEP 7 | Delete app cache/config: %AppData%\\AppName or %LocalAppData%\\AppName",
  "STEP 8 | Right-click app > Properties > Compatibility > Run compatibility troubleshooter",
  "STEP 9 | Check app vendor's support page for known issues / patches"
]).

solution(driver_conflict, [
  "STEP 1 | devmgmt.msc — find devices with yellow ! (error) or ? (unknown)",
  "STEP 2 | Right-click device > Properties > check error code",
  "STEP 3 | Right-click > Update driver > Search automatically",
  "STEP 4 | If problem started after update: Right-click > Properties > Driver > Roll Back",
  "STEP 5 | Uninstall device, then Action > Scan for hardware changes to reinstall",
  "STEP 6 | Download driver directly from hardware manufacturer (not Windows Update)",
  "STEP 7 | For GPU: use DDU (Display Driver Uninstaller) in Safe Mode for clean reinstall"
]).

solution(disk_full, [
  "STEP 1 | cleanmgr.exe > 'Clean up system files' — reclaim GBs quickly",
  "STEP 2 | Settings > System > Storage — enable Storage Sense and Run Now",
  "STEP 3 | WinDirStat or TreeSize Free — visualise what's consuming space",
  "STEP 4 | Uninstall unused apps: Settings > Apps & Features",
  "STEP 5 | Delete Windows.old folder (left from previous Windows version)",
  "STEP 6 | Clear %TEMP% and C:\\Windows\\Temp",
  "STEP 7 | Move large files (videos, backups) to external drive or cloud",
  "STEP 8 | Empty Recycle Bin",
  "STEP 9 | Disable hibernation if unused: powercfg /h off  (reclaims RAM-size GBs)"
]).

solution(missing_runtime, [
  "STEP 1 | Note exact DLL name in error message",
  "STEP 2 | Install latest Visual C++ Redistributables (2015-2022 x64 and x86):",
  "         Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe",
  "STEP 3 | Install .NET Framework required version (check app documentation)",
  "STEP 4 | Install DirectX End-User Runtime if DLL is d3dx or xinput related",
  "STEP 5 | Run sfc /scannow to restore any corrupted system DLLs",
  "STEP 6 | Do NOT download DLLs from random dll-download sites (malware risk)"
]).

solution(malware, [
  "STEP 1 | Disconnect from the internet immediately",
  "STEP 2 | Boot into Safe Mode with Networking (hold Shift > Restart)",
  "STEP 3 | Run Windows Defender full scan",
  "STEP 4 | Download and run Malwarebytes Free — full scan",
  "STEP 5 | Run AdwCleaner for adware and browser hijackers",
  "STEP 6 | Check and reset browser extensions (remove unknown ones)",
  "STEP 7 | Reset browser settings to default in Chrome/Firefox/Edge",
  "STEP 8 | Change passwords for all important accounts from a CLEAN device",
  "STEP 9 | Enable Windows Firewall if it was disabled",
  "STEP 10| Monitor for recurrence — if persistent, consider OS reinstall"
]).

solution(ransomware, [
  "!!! CRITICAL INCIDENT — FOLLOW THESE STEPS IN ORDER !!!",
  "STEP 1 | IMMEDIATELY disconnect all network cables and disable Wi-Fi",
  "STEP 2 | Do NOT pay the ransom — no guarantee of recovery, funds crime",
  "STEP 3 | Isolate ALL devices on the same network segment",
  "STEP 4 | Report to management, legal, and data protection officer (GDPR obligations)",
  "STEP 5 | Identify ransomware family at: https://id-ransomware.malwarehunterteam.com",
  "STEP 6 | Check for free decryption tools at: https://www.nomoreransom.org",
  "STEP 7 | DO NOT wipe machines yet — preserve forensic evidence",
  "STEP 8 | Restore from clean offline backup if available",
  "STEP 9 | Wipe and rebuild from trusted media if no backup exists",
  "STEP 10| Conduct full post-incident security review before reconnecting"
]).

solution(account_lockout, [
  "STEP 1 | Wait for lockout duration (usually 30 min) or ask admin to unlock",
  "STEP 2 | Event Viewer > Security — filter for Event ID 4625 (logon failure)",
  "STEP 3 | Check for devices still using old/expired password (phones, tablets)",
  "STEP 4 | Check mapped network drives — update credentials",
  "STEP 5 | Check scheduled tasks running with old credentials",
  "STEP 6 | Check Windows services running as the user account",
  "STEP 7 | Use Microsoft LockoutStatus.exe to find the lockout source DC",
  "STEP 8 | After unlocking, change password and update everywhere"
]).

solution(account_compromise, [
  "STEP 1 | Change password IMMEDIATELY from a clean, uncompromised device",
  "STEP 2 | Enable Multi-Factor Authentication (MFA) on the account NOW",
  "STEP 3 | Review account activity log / sign-in history for unknown locations",
  "STEP 4 | Revoke all active sessions (most email providers have this option)",
  "STEP 5 | Check email rules / auto-forward — attackers add silent forwarding",
  "STEP 6 | Scan the original device for malware before using again",
  "STEP 7 | Notify affected contacts — your account may have sent phishing emails",
  "STEP 8 | Report to IT security team / MSSP immediately"
]).

solution(firewall_blocking, [
  "STEP 1 | wf.msc — open Windows Firewall with Advanced Security",
  "STEP 2 | Check Inbound and Outbound rules for the application or port",
  "STEP 3 | Temporarily disable firewall: netsh advfirewall set allprofiles state off",
  "         (RE-ENABLE immediately after test: ...set allprofiles state on)",
  "STEP 4 | Allow app through firewall: Control Panel > Firewall > Allow an app",
  "STEP 5 | Create specific inbound rule for required TCP/UDP port",
  "STEP 6 | Check corporate proxy settings: netsh winhttp show proxy",
  "STEP 7 | Review third-party security suite firewall (Norton, McAfee, etc.)"
]).

solution(printer_offline, [
  "STEP 1 | Check printer is powered on, connected, and not showing error lights",
  "STEP 2 | Set as default printer: Control Panel > Devices and Printers",
  "STEP 3 | Clear print queue and restart spooler:",
  "         net stop spooler",
  "         del /Q /F /S %systemroot%\\System32\\spool\\PRINTERS\\*",
  "         net start spooler",
  "STEP 4 | Right-click printer > See what's printing > Printer > Uncheck 'Use Printer Offline'",
  "STEP 5 | Remove and re-add the printer",
  "STEP 6 | For network printers: confirm IP hasn't changed — update port if needed"
]).

solution(printer_driver, [
  "STEP 1 | Download latest driver from printer manufacturer website (not Windows Update)",
  "STEP 2 | Fully uninstall current driver: Devices > Printers > Remove device",
  "         Also remove via Print Management (printmanagement.msc) > Drivers",
  "STEP 3 | Reboot, then install fresh driver",
  "STEP 4 | For shared network printer: ensure server-side driver matches client OS arch (x64)",
  "STEP 5 | Try adding printer via IP address directly instead of auto-discovery"
]).

solution(email_send_fail, [
  "STEP 1 | Confirm internet connectivity first",
  "STEP 2 | Check outgoing SMTP settings:",
  "         Port 587 with STARTTLS  (recommended)",
  "         Port 465 with SSL/TLS",
  "         Port 25  (often blocked by ISPs)",
  "STEP 3 | Verify username/password (re-enter — may have changed)",
  "STEP 4 | Check Outbox — delete large/stuck messages and retry",
  "STEP 5 | For Outlook: create new mail profile (control panel > mail > profiles)",
  "STEP 6 | Check if account requires App Password (if MFA enabled with legacy clients)",
  "STEP 7 | Check provider status page for outages"
]).

solution(email_recv_fail, [
  "STEP 1 | Check mailbox quota — delete old emails or empty Deleted Items",
  "STEP 2 | Ask sender to check their bounce/NDR message for clues",
  "STEP 3 | Check Junk/Spam folder — important mail may be filtered",
  "STEP 4 | Verify POP3/IMAP settings and port numbers",
  "         IMAP: port 993 SSL  |  POP3: port 995 SSL",
  "STEP 5 | Check email rules — a rule may be moving/deleting messages",
  "STEP 6 | Log in via webmail to confirm mail arrives server-side",
  "STEP 7 | If corporate: contact mail admin to check MX records and mail flow logs"
]).

solution(av_comms_issue, [
  "STEP 1 | Check microphone/camera permissions: Settings > Privacy > Mic / Camera",
  "STEP 2 | Ensure the correct device is selected in the app's audio/video settings",
  "STEP 3 | Update audio and webcam drivers from Device Manager",
  "STEP 4 | Test mic/cam in Windows Settings > Bluetooth & devices > Camera/Sound",
  "STEP 5 | Close other apps that might hold exclusive access to mic/camera",
  "STEP 6 | For Teams/Zoom: clear app cache and reinstall",
  "STEP 7 | Check antivirus or endpoint security blocking camera access"
]).

/* ================================================================
   SYMPTOM QUESTIONS
   symptom_question(SymbolAtom, 'Question text shown to user')
   ================================================================ */

symptom_question(ping_ip_fails,
    "Does  ping 8.8.8.8  fail? (raw IP reachability test)").
symptom_question(no_dhcp_address,
    "Does  ipconfig /all  show a 169.x.x.x address or no IP at all?").
symptom_question(ping_name_fails,
    "Does  ping google.com  fail while  ping 8.8.8.8  succeeds?").
symptom_question(internet_slow,
    "Is internet noticeably slow (pages take a very long time to load)?").
symptom_question(high_bandwidth_apps,
    "Is a background app (Teams, OneDrive, Windows Update) using heavy bandwidth?").
symptom_question(wifi_not_connecting,
    "Is Wi-Fi failing to connect or authenticate to the access point?").
symptom_question(ethernet_works,
    "Does a wired Ethernet connection work when Wi-Fi does not?").
symptom_question(adapter_error_devmgr,
    "Is there a yellow ! or ? on the network adapter in Device Manager?").
symptom_question(vpn_fails_to_connect,
    "Does the VPN client fail to establish a connection?").
symptom_question(internet_works_no_vpn,
    "Does internet browsing work fine when the VPN is disconnected?").
symptom_question(os_wont_boot,
    "Does the OS completely fail to boot (gets stuck before login screen)?").
symptom_question(bios_posts_ok,
    "Does the initial BIOS/firmware POST screen appear before the failure?").
symptom_question(blue_screen_appears,
    "Do you see a Blue Screen of Death (BSOD) with a STOP error code?").
symptom_question(system_reboots_itself,
    "Does the system reboot itself unexpectedly without warning?").
symptom_question(system_freezes,
    "Does the system completely freeze and become fully unresponsive?").
symptom_question(high_cpu_usage,
    "Is CPU usage above 90% continuously in Task Manager?").
symptom_question(computer_slow,
    "Is the computer generally sluggish with long delays on all tasks?").
symptom_question(high_disk_usage,
    "Is Disk usage showing 100% frequently in Task Manager?").
symptom_question(updates_fail,
    "Do Windows updates fail to install and roll back?").
symptom_question(update_error_code,
    "Is a specific error code displayed when updates fail (e.g. 0x80070057)?").
symptom_question(settings_reset_on_login,
    "Are your desktop/settings being reset to defaults every time you log in?").
symptom_question(temp_profile_warning,
    "Do you see a 'You have been signed in with a temporary profile' warning?").
symptom_question(hdd_clicking_noise,
    "Do you hear clicking, grinding or unusual sounds from the hard drive?").
symptom_question(disk_read_errors,
    "Are there disk-related read/write errors in Event Viewer or during boot?").
symptom_question(random_crashes,
    "Does the system crash or shut off suddenly without a BSOD (instant off)?").
symptom_question(memory_dump_err,
    "Do crash dumps or Event Viewer show memory/pool corruption errors?").
symptom_question(high_temps,
    "Are hardware temperatures critically high (CPU above 90°C)?").
symptom_question(throttles_or_shuts,
    "Does the system throttle performance or shut down suddenly under load?").
symptom_question(no_power_at_all,
    "Does the computer completely fail to power on (no lights, no fans)?").
symptom_question(random_power_off,
    "Does the system suddenly lose power and shut off under medium-to-heavy load?").
symptom_question(no_display_output,
    "Is there no image on the monitor (black screen / no signal) at all?").
symptom_question(screen_artifacts,
    "Do you see visual glitches, lines, blocks or corruption on screen?").
symptom_question(usb_not_detected,
    "Is a USB device not detected or not recognised when plugged in?").
symptom_question(device_works_elsewhere,
    "Does the same USB device work correctly on another computer?").
symptom_question(specific_app_crashes,
    "Does one specific application crash while the rest of the system is fine?").
symptom_question(crash_on_launch,
    "Does the application crash immediately when you try to launch it?").
symptom_question(device_stopped_working,
    "Has a hardware device (printer, webcam, etc.) suddenly stopped working?").
symptom_question(yellow_bang_devmgr,
    "Is there a yellow exclamation mark on any device in Device Manager?").
symptom_question(disk_nearly_full,
    "Is your C: drive nearly full (less than 10% free space remaining)?").
symptom_question(cant_save_files,
    "Are you unable to save files due to insufficient disk space errors?").
symptom_question(dll_not_found_error,
    "Do you see a 'DLL not found' or 'VCRUNTIME / MSVCP missing' error?").
symptom_question(app_worked_before,
    "Did this application work correctly before (not a fresh install issue)?").
symptom_question(suspicious_popups,
    "Are there unexpected pop-ups, browser redirects, or new toolbars appearing?").
symptom_question(antivirus_alert,
    "Is antivirus or Windows Defender showing active threat alerts?").
symptom_question(files_encrypted,
    "Have files been renamed with strange extensions and become unreadable?").
symptom_question(ransom_note_found,
    "Is there a ransom demand note (text/HTML file) on the desktop or in folders?").
symptom_question(cant_login,
    "Are you unable to log in to a Windows or domain account?").
symptom_question(lockout_msg_shown,
    "Is a 'Your account has been locked' message displayed on login?").
symptom_question(unexpected_sent_mail,
    "Are people reporting receiving unexpected emails sent from your account?").
symptom_question(unknown_login_alerts,
    "Are you receiving login alerts for sign-ins you did not perform?").
symptom_question(app_blocked_firewall,
    "Is an application showing firewall or access-denied connection errors?").
symptom_question(connection_timeout,
    "Are connections to a specific app or server timing out consistently?").
symptom_question(printer_shows_offline,
    "Does the printer show as 'Offline' in Devices and Printers?").
symptom_question(print_queue_stuck,
    "Are print jobs stuck in the queue and the queue cannot be cleared?").
symptom_question(printer_driver_error,
    "Is there a driver error shown when trying to install or use the printer?").
symptom_question(reinstall_fixed_it,
    "Did simply reinstalling the printer driver fix the problem previously?").
symptom_question(emails_stuck_outbox,
    "Are outgoing emails stuck in the Outbox and not being sent?").
symptom_question(smtp_error_shown,
    "Is an SMTP or send-error message displayed in your mail client?").
symptom_question(no_incoming_email,
    "Are incoming emails not arriving at all?").
symptom_question(mailbox_quota_full,
    "Is your mailbox quota full or nearly full?").
symptom_question(mic_or_cam_not_working,
    "Is the microphone or camera not working in Teams, Zoom, or similar apps?").
symptom_question(works_in_other_apps,
    "Does the mic/camera work in other applications or the OS settings?").

/* ================================================================
   INFERENCE ENGINE — check/4
   Retrieves stored fact or prompts the user
   ================================================================ */

check(Symptom, ExpectedAnswer, Weight, CF) :-
    ( fact(Symptom, Stored) ->
        ActualAnswer = Stored
    ;
        ask_user(Symptom, ActualAnswer),
        assertz(fact(Symptom, ActualAnswer))
    ),
    ( ActualAnswer == ExpectedAnswer ->
        CF is Weight
    ; ActualAnswer == unknown ->
        CF is 0.0
    ;
        CF is -Weight
    ).

ask_user(Symptom, Answer) :-
    ( asked(Symptom)
    -> ( fact(Symptom, Answer) -> true ; Answer = unknown )
    ;  assertz(asked(Symptom)),
       symptom_question(Symptom, Question),
       repeat,
           nl,
           format("  ~`-t~62|~n"),
           format("  Q: ~w~n", [Question]),
           format("  ~`-t~62|~n"),
           format("  Your answer  [yes / no / unknown] : "),
           catch(
               ( read_term(Raw, [variable_names([])]),
                 ( member(Raw, [yes, no, unknown])
                 -> Answer = Raw, !
                 ;  format("  >> Please type  yes.  or  no.  or  unknown.~n"),
                    fail
                 )
               ),
               _,
               ( format("  >> Input error — please type  yes.  no.  or  unknown.~n"),
                 fail
               )
           )
    ).

/* ================================================================
   DIAGNOSIS RUNNER
   ================================================================ */

run_diagnoses(Names, Sorted) :-
    cf_threshold(T),
    findall(
        diag(Name, CF),
        ( member(Name, Names),
          catch(diagnosis(Name, CF), _, fail),
          CF >= T
        ),
        Raw
    ),
    sort(2, @>=, Raw, Sorted).

all_diagnosis_names([
    no_internet, dns_failure, slow_network, wifi_problem,
    network_adapter_issue, vpn_problem,
    boot_failure, bsod, system_freeze, slow_performance,
    update_failure, profile_corruption,
    hdd_failure, ram_failure, overheating, psu_failure,
    display_problem, usb_issue,
    app_crash, driver_conflict, disk_full, missing_runtime,
    malware, ransomware, account_lockout, account_compromise,
    firewall_blocking,
    printer_offline, printer_driver,
    email_send_fail, email_recv_fail, av_comms_issue
]).

category_names(1, [no_internet, dns_failure, slow_network, wifi_problem,
                   network_adapter_issue, vpn_problem]).
category_names(2, [boot_failure, bsod, system_freeze, slow_performance,
                   update_failure, profile_corruption]).
category_names(3, [hdd_failure, ram_failure, overheating, psu_failure,
                   display_problem, usb_issue]).
category_names(4, [app_crash, driver_conflict, disk_full, missing_runtime]).
category_names(5, [malware, ransomware, account_lockout, account_compromise,
                   firewall_blocking]).
category_names(6, [printer_offline, printer_driver]).
category_names(7, [email_send_fail, email_recv_fail, av_comms_issue]).

/* ================================================================
   DISPLAY HELPERS
   ================================================================ */

banner :-
    nl,
    format("  ╔══════════════════════════════════════════════════════════╗~n"),
    format("  ║     SMART IT TECHNICAL SUPPORT EXPERT SYSTEM            ║~n"),
    format("  ║     SWI-Prolog · Backward Chaining · MYCIN CF Engine    ║~n"),
    format("  ╚══════════════════════════════════════════════════════════╝~n"),
    nl.

sep :-
    format("  ~`═t~62|~n").

thin_sep :-
    format("  ~`─t~62|~n").

cf_label(CF, Stars, Label) :-
    ( CF >= 0.90 -> Stars = "★★★★★", Label = "VERY HIGH"
    ; CF >= 0.75 -> Stars = "★★★★☆", Label = "HIGH"
    ; CF >= 0.60 -> Stars = "★★★☆☆", Label = "MODERATE"
    ; CF >= 0.45 -> Stars = "★★☆☆☆", Label = "LOW-MODERATE"
    ;               Stars = "★☆☆☆☆", Label = "LOW"
    ).

friendly_name(no_internet,         "No Internet Connectivity").
friendly_name(dns_failure,         "DNS Resolution Failure").
friendly_name(slow_network,        "Slow Network / Bandwidth Issue").
friendly_name(wifi_problem,        "Wi-Fi Connection Problem").
friendly_name(network_adapter_issue,"Network Adapter Error").
friendly_name(vpn_problem,         "VPN Connectivity Problem").
friendly_name(boot_failure,        "OS Boot Failure").
friendly_name(bsod,                "Blue Screen of Death (BSOD)").
friendly_name(system_freeze,       "System Freeze / Hang").
friendly_name(slow_performance,    "Slow System Performance").
friendly_name(update_failure,      "Windows Update Failure").
friendly_name(profile_corruption,  "User Profile Corruption").
friendly_name(hdd_failure,         "Hard Drive / SSD Failure").
friendly_name(ram_failure,         "RAM / Memory Failure").
friendly_name(overheating,         "Hardware Overheating").
friendly_name(psu_failure,         "Power Supply (PSU) Problem").
friendly_name(display_problem,     "Display / GPU Problem").
friendly_name(usb_issue,           "USB Device Not Recognised").
friendly_name(app_crash,           "Application Crash").
friendly_name(driver_conflict,     "Device Driver Conflict").
friendly_name(disk_full,           "Disk Drive Full").
friendly_name(missing_runtime,     "Missing Runtime / DLL Error").
friendly_name(malware,             "Malware / Virus Infection").
friendly_name(ransomware,          "Ransomware Attack").
friendly_name(account_lockout,     "User Account Lockout").
friendly_name(account_compromise,  "Account Compromise / Breach").
friendly_name(firewall_blocking,   "Firewall Blocking Application").
friendly_name(printer_offline,     "Printer Offline / Not Printing").
friendly_name(printer_driver,      "Printer Driver Problem").
friendly_name(email_send_fail,     "Email Not Sending (SMTP)").
friendly_name(email_recv_fail,     "Email Not Receiving (IMAP/POP3)").
friendly_name(av_comms_issue,      "Mic / Camera Not Working").

print_result(diag(Name, CF), Rank) :-
    Pct is round(CF * 100),
    cf_label(CF, Stars, CLabel),
    friendly_name(Name, FName),
    nl,
    sep,
    format("  DIAGNOSIS #~w~n", [Rank]),
    thin_sep,
    format("  Problem    : ~w~n", [FName]),
    format("  Confidence : ~w%  ~w  [~w]~n", [Pct, Stars, CLabel]),
    sep,
    nl,
    format("  RECOMMENDED FIX STEPS:~n"),
    thin_sep,
    ( solution(Name, Steps)
    -> forall(member(S, Steps), format("   ~w~n", [S]))
    ;  format("   (No automated solution steps defined for this issue.)~n")
    ),
    nl.

print_no_results :-
    nl,
    sep,
    format("  No diagnosis reached the confidence threshold.~n"),
    format("~n"),
    format("  This means either:~n"),
    format("   • The symptoms do not match any known pattern~n"),
    format("   • Many answers were 'unknown' — try again with more info~n"),
    format("   • The problem may be in a different category~n"),
    sep,
    nl.

print_results([]) :- print_no_results.
print_results(Results) :-
    Results \= [],
    length(Results, N),
    nl,
    format("  ~w diagnosis/diagnoses found (sorted by confidence):~n", [N]),
    print_results_numbered(Results, 1).

print_results_numbered([], _).
print_results_numbered([H|T], N) :-
    print_result(H, N),
    N1 is N + 1,
    print_results_numbered(T, N1).

/* ================================================================
   HELP SCREEN
   ================================================================ */

print_help :-
    nl, sep,
    format("  HOW TO USE THIS EXPERT SYSTEM~n"),
    sep, nl,
    format("  1. Choose a problem CATEGORY from the main menu~n"),
    format("     (or option 8 to scan all categories at once)~n~n"),
    format("  2. Answer symptom questions honestly:~n"),
    format("       yes.     — symptom IS present~n"),
    format("       no.      — symptom is NOT present~n"),
    format("       unknown. — you are not sure~n~n"),
    format("  3. IMPORTANT — always end your answer with a FULL STOP  ( . )~n"),
    format("     Example:  yes.    not just   yes~n~n"),
    format("  4. Results are ranked by CONFIDENCE (0–100%)~n"),
    format("     Diagnoses below 30% confidence are hidden~n~n"),
    format("  5. After results, press ENTER to return to the main menu~n~n"),
    format("  6. Symptoms answered in one session are remembered~n"),
    format("     Use option [R] to start a completely fresh session~n~n"),
    format("  CONFIDENCE SCALE:~n"),
    format("    ★★★★★  90-100%%  Very High — strong match~n"),
    format("    ★★★★☆  75-89%%   High      — likely match~n"),
    format("    ★★★☆☆  60-74%%   Moderate  — probable match~n"),
    format("    ★★☆☆☆  45-59%%   Low-Mod   — possible match~n"),
    format("    ★☆☆☆☆  30-44%%   Low       — weak match~n~n"),
    sep, nl.

/* ================================================================
   MAIN MENU LOOP
   ================================================================ */

print_menu :-
    banner,
    format("  Select a problem category:~n~n"),
    format("   [1]  Network & Connectivity~n"),
    format("   [2]  Operating System (Windows)~n"),
    format("   [3]  Hardware~n"),
    format("   [4]  Software & Applications~n"),
    format("   [5]  Security & Malware~n"),
    format("   [6]  Printers~n"),
    format("   [7]  Email & Communications~n"),
    format("   [8]  Full Diagnostic (all categories)~n"),
    format("   [H]  Help / How to use~n"),
    format("   [R]  Reset session (clear all answers)~n"),
    format("   [Q]  Quit~n~n"),
    format("  Your choice: ").

reset_session :-
    retractall(fact(_, _)),
    retractall(asked(_)),
    retractall(session_log(_)),
    nl,
    format("  Session reset. All previous answers cleared.~n"), nl.

run_category(Choice) :-
    integer(Choice),
    member(Choice, [1,2,3,4,5,6,7]),
    !,
    category_names(Choice, Names),
    format("~n  Running diagnostic...~n"),
    run_diagnoses(Names, Results),
    print_results(Results).

run_category(8) :-
    !,
    all_diagnosis_names(Names),
    format("~n  Running full diagnostic across all categories...~n"),
    run_diagnoses(Names, Results),
    print_results(Results).

run_category(h) :- !, print_help.
run_category('H') :- !, print_help.

run_category(r) :- !, reset_session.
run_category('R') :- !, reset_session.

run_category(q) :- !, throw(quit).
run_category('Q') :- !, throw(quit).

run_category(_) :-
    format("~n  Invalid choice. Please enter a number 1-8, H, R, or Q.~n~n").

/* ================================================================
   ENTRY POINT
   ================================================================ */

run :-
    banner,
    format("  Welcome! This system diagnoses common IT problems~n"),
    format("  using backward chaining and certainty factors.~n"),
    format("  Type  H.  at the menu for instructions.~n~n"),
    catch(
        main_loop,
        quit,
        ( nl, format("  Thank you for using the Smart IT Expert System. Goodbye!~n"), nl )
    ).

main_loop :-
    repeat,
        print_menu,
        catch(
            read_term(Choice, [variable_names([])]),
            _,
            ( format("  >> Input error — try again.~n"), fail )
        ),
        catch(
            run_category(Choice),
            Error,
            ( format("  >> Unexpected error: ~w~n", [Error]), true )
        ),
        nl,
        format("  Press ENTER (type  c.  then Enter) to return to menu...~n"),
        catch(read_term(_, []), _, true),
        fail. % keep looping

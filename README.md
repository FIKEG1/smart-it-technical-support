# Smart IT Technical Support Expert System
### SWI-Prolog · Backward Chaining · MYCIN Certainty Factors

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [How to Install SWI-Prolog](#3-how-to-install-swi-prolog)
4. [How to Run the System](#4-how-to-run-the-system)
5. [How to Use — Step by Step](#5-how-to-use--step-by-step)
6. [Knowledge Base Coverage](#6-knowledge-base-coverage)
7. [How the Inference Engine Works](#7-how-the-inference-engine-works)
8. [Certainty Factor (CF) Explained](#8-certainty-factor-cf-explained)
9. [File Structure & Code Map](#9-file-structure--code-map)
10. [How to Extend the System](#10-how-to-extend-the-system)
11. [Example Session Walkthrough](#11-example-session-walkthrough)
12. [Troubleshooting the System Itself](#12-troubleshooting-the-system-itself)

---

## 1. Project Overview

The **Smart IT Technical Support Expert System** is a knowledge-based AI system
implemented in SWI-Prolog. It diagnoses 32 common IT problems across 7 categories
using **backward-chaining inference** and **MYCIN-style certainty factors**.

The system:
- Asks targeted yes/no questions about observed symptoms
- Scores each possible diagnosis with a confidence value (0–100%)
- Returns ranked diagnoses with step-by-step remediation guides
- Remembers answers within a session to avoid repeated questions
- Provides an explanation of confidence level for each result

**This is not a simple decision tree.** It is a true expert system:
- Rules fire in parallel across all diagnoses in a category
- Evidence accumulates from multiple symptoms per diagnosis
- Conflicting evidence (yes vs no answers) is handled mathematically
- Unknown answers contribute zero evidence rather than blocking

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────┐
│             USER INTERFACE LAYER                 │
│   main_loop/0 · print_menu/0 · print_results/1  │
└───────────────────┬─────────────────────────────┘
                    │ read_term/2 input
┌───────────────────▼─────────────────────────────┐
│             INFERENCE ENGINE                     │
│   check/4 · ask_user/2 · run_diagnoses/2         │
│   Backward chaining from goal → symptoms         │
└──────────┬────────────────┬────────────────────-─┘
           │                │
┌──────────▼──────┐  ┌──────▼──────────────────────┐
│  KNOWLEDGE BASE │  │      WORKING MEMORY          │
│  diagnosis/2    │  │  dynamic fact/2              │
│  solution/2     │  │  dynamic asked/1             │
│  symptom_       │  │  dynamic session_log/1       │
│  question/2     │  │  (cleared on reset)          │
│  friendly_name  │  └─────────────────────────────-┘
│  cf_threshold   │
└─────────────────┘
```

### Key Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Inference strategy | Backward chaining | Start from hypotheses, gather only needed evidence |
| Uncertainty model | MYCIN CF arithmetic | Handles partial/conflicting evidence gracefully |
| Knowledge representation | Prolog clauses | Declarative, easy to read and extend |
| Working memory | Dynamic predicates | Session-scoped, resettable |
| UI | Terminal CLI with menus | Works on any platform without dependencies |

---

## 3. How to Install SWI-Prolog

### Windows
1. Go to: https://www.swi-prolog.org/download/stable
2. Download the Windows 64-bit installer (`.exe`)
3. Run the installer — accept defaults
4. SWI-Prolog will be in your Start Menu
5. `swipl` will be available in Command Prompt if you tick "Add to PATH"

### macOS
```bash
# Using Homebrew (recommended):
brew install swi-prolog

# Or download from: https://www.swi-prolog.org/download/stable
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install swi-prolog
```

### Linux (Fedora/RHEL)
```bash
sudo dnf install pl
```

### Verify Installation
```bash
swipl --version
# Should print something like: SWI-Prolog version 9.x.x
```

---

## 4. How to Run the System

### Method 1 — Command line (recommended)
```bash
# Navigate to the project folder:
cd /path/to/smart_it_expert_system

# Run directly (starts and calls run/0 automatically):
swipl -g run expert_system.pl

# Or run and stay in interactive Prolog shell after:
swipl expert_system.pl
# Then at the ?- prompt type:
?- run.
```

### Method 2 — From SWI-Prolog IDE (SWI-Prolog GUI)
1. Open SWI-Prolog
2. File → Consult → select `expert_system.pl`
3. In the bottom query box type: `run.` and press Enter

### Method 3 — Double-click (Windows)
- Right-click `expert_system.pl` → Open with → SWI-Prolog
- Type `run.` in the window that opens

---

## 5. How to Use — Step by Step

### At the main menu
```
   [1]  Network & Connectivity
   [2]  Operating System (Windows)
   [3]  Hardware
   [4]  Software & Applications
   [5]  Security & Malware
   [6]  Printers
   [7]  Email & Communications
   [8]  Full Diagnostic (all categories)
   [H]  Help / How to use
   [R]  Reset session (clear all answers)
   [Q]  Quit

  Your choice:
```
Type the number or letter and press **Enter**.

### Answering symptom questions

⚠️ **CRITICAL: Always type a full stop ( . ) after your answer**

```
  ──────────────────────────────────────────────────────────────
  Q: Does ping 8.8.8.8 fail? (raw IP reachability test)
  ──────────────────────────────────────────────────────────────
  Your answer  [yes / no / unknown] : yes.
                                          ↑
                                    Full stop required!
```

| Answer | When to use |
|--------|-------------|
| `yes.` | The symptom IS present / the statement IS true |
| `no.` | The symptom is NOT present / the statement is FALSE |
| `unknown.` | You are not sure or cannot check |

### Reading results
```
  ══════════════════════════════════════════════════════════════
  DIAGNOSIS #1
  ──────────────────────────────────────────────────────────────
  Problem    : No Internet Connectivity
  Confidence : 97%  ★★★★★  [VERY HIGH]
  ══════════════════════════════════════════════════════════════

  RECOMMENDED FIX STEPS:
  ──────────────────────────────────────────────────────────────
   STEP 1 | ipconfig /all — check you have a valid IP ...
   STEP 2 | ping 8.8.8.8 — test raw IP reachability
   ...
```

Multiple diagnoses can appear — work through the highest-confidence one first.

---

## 6. Knowledge Base Coverage

### Category 1 — Network & Connectivity (6 diagnoses)
| ID | Problem |
|----|---------|
| no_internet | No Internet Connectivity |
| dns_failure | DNS Resolution Failure |
| slow_network | Slow Network / Bandwidth Issue |
| wifi_problem | Wi-Fi Connection Problem |
| network_adapter_issue | Network Adapter Error |
| vpn_problem | VPN Connectivity Problem |

### Category 2 — Operating System (6 diagnoses)
| ID | Problem |
|----|---------|
| boot_failure | OS Boot Failure |
| bsod | Blue Screen of Death (BSOD) |
| system_freeze | System Freeze / Hang |
| slow_performance | Slow System Performance |
| update_failure | Windows Update Failure |
| profile_corruption | User Profile Corruption |

### Category 3 — Hardware (6 diagnoses)
| ID | Problem |
|----|---------|
| hdd_failure | Hard Drive / SSD Failure |
| ram_failure | RAM / Memory Failure |
| overheating | Hardware Overheating |
| psu_failure | Power Supply (PSU) Problem |
| display_problem | Display / GPU Problem |
| usb_issue | USB Device Not Recognised |

### Category 4 — Software & Applications (4 diagnoses)
| ID | Problem |
|----|---------|
| app_crash | Application Crash |
| driver_conflict | Device Driver Conflict |
| disk_full | Disk Drive Full |
| missing_runtime | Missing Runtime / DLL Error |

### Category 5 — Security & Malware (5 diagnoses)
| ID | Problem |
|----|---------|
| malware | Malware / Virus Infection |
| ransomware | Ransomware Attack |
| account_lockout | User Account Lockout |
| account_compromise | Account Compromise / Breach |
| firewall_blocking | Firewall Blocking Application |

### Category 6 — Printers (2 diagnoses)
| ID | Problem |
|----|---------|
| printer_offline | Printer Offline / Not Printing |
| printer_driver | Printer Driver Problem |

### Category 7 — Email & Communications (3 diagnoses)
| ID | Problem |
|----|---------|
| email_send_fail | Email Not Sending (SMTP) |
| email_recv_fail | Email Not Receiving (IMAP/POP3) |
| av_comms_issue | Mic / Camera Not Working |

**Total: 32 diagnoses · 50+ symptom questions · 32 solution guides**

---

## 7. How the Inference Engine Works

### Backward Chaining Explained

Instead of going through all facts looking for conclusions (forward chaining),
backward chaining starts from a **goal** (a hypothesis/diagnosis) and works
backwards to find supporting evidence.

```
GOAL: Is this "no_internet"?
  → Need: check(ping_ip_fails, yes)   ← ASK USER
  → Need: check(no_dhcp_address, yes) ← ASK USER
  → Combine CFs → final confidence score
```

This means the system **only asks questions relevant to the current hypotheses**.
If you pick Category 1 (Network), it never asks about hard drives or RAM.

### The check/4 Predicate — Core Logic

```prolog
check(Symptom, ExpectedAnswer, Weight, CF) :-
    % 1. If we already know the answer (from previous question), use it
    ( fact(Symptom, Stored) ->
        ActualAnswer = Stored
    ;
    % 2. Otherwise ask the user, store the answer for reuse
        ask_user(Symptom, ActualAnswer),
        assertz(fact(Symptom, ActualAnswer))
    ),
    % 3. Convert yes/no/unknown to a CF value
    ( ActualAnswer == ExpectedAnswer -> CF is Weight    % Evidence supports
    ; ActualAnswer == unknown        -> CF is 0.0       % No evidence either way
    ;                                   CF is -Weight   % Evidence contradicts
    ).
```

### Diagnosis Rule Example

```prolog
diagnosis(no_internet, CF) :-
    check(ping_ip_fails,   yes, 0.90, C1),  % 90% weight if true
    check(no_dhcp_address, yes, 0.70, C2),  % 70% weight if true
    combine_cf(C1, C2, CF).                 % MYCIN combination
```

If both symptoms are `yes`: CF = 0.90 + 0.70×(1-0.90) = **0.97 (97%)**
If first is `yes`, second `no`: CF = 0.90 + (-0.70)×... ≈ **0.39 (39%)**
If first is `yes`, second `unknown`: CF = 0.90 + 0.0 = **0.90 (90%)**

---

## 8. Certainty Factor (CF) Explained

The system uses MYCIN-style CF arithmetic — the same approach used in the
famous medical diagnosis expert system from Stanford.

### CF Scale
```
+1.0  → Definitely true
+0.5  → Fairly likely true
 0.0  → Unknown / no evidence
-0.5  → Fairly likely false
-1.0  → Definitely false
```

### Combination Rules

**Both positive (both symptoms present):**
```
CF = CF1 + CF2 × (1 - CF1)
```
Example: 0.9 + 0.7 × 0.1 = 0.97

**Both negative (both symptoms absent):**
```
CF = CF1 + CF2 × (1 + CF1)
```

**Mixed sign (conflicting evidence):**
```
CF = (CF1 + CF2) / (1 - min(|CF1|, |CF2|))
```

### Confidence Display

| CF Range | Stars | Label |
|----------|-------|-------|
| 90–100% | ★★★★★ | Very High |
| 75–89% | ★★★★☆ | High |
| 60–74% | ★★★☆☆ | Moderate |
| 45–59% | ★★☆☆☆ | Low-Moderate |
| 30–44% | ★☆☆☆☆ | Low |
| < 30% | (hidden) | Below threshold |

---

## 9. File Structure & Code Map

```
smart_it_expert_system/
└── expert_system.pl          ← Single-file system (1067 lines)
    │
    ├── SECTION: Dynamic facts declarations (lines ~14-18)
    │   fact/2, asked/1, session_log/1
    │
    ├── SECTION: CF Engine (lines ~25-37)
    │   combine_cf/3, cf_threshold/1
    │
    ├── SECTION: Knowledge Base (lines ~44-530)
    │   diagnosis/2     — 32 rules, one per problem
    │   solution/2      — 32 solution guides
    │   symptom_question/2 — 50+ question strings
    │
    ├── SECTION: Inference Engine (lines ~764-800)
    │   check/4         — core symptom checker
    │   ask_user/2      — interactive Q&A with repeat loop
    │
    ├── SECTION: Diagnosis Runner (lines ~803-835)
    │   run_diagnoses/2        — runs a list of diagnosis names
    │   all_diagnosis_names/1  — full list of all 32 names
    │   category_names/2       — maps category 1-7 to name lists
    │
    ├── SECTION: Display Helpers (lines ~838-905)
    │   banner/0, sep/0, thin_sep/0
    │   cf_label/3, friendly_name/2, print_result/2
    │   print_results/1, print_no_results/0
    │
    ├── SECTION: Help & Menu (lines ~908-990)
    │   print_help/0, print_menu/0
    │
    └── SECTION: Main Loop (lines ~993-1067)
        run/0            — entry point (call this)
        main_loop/0      — repeat loop for the UI
        run_category/1   — dispatcher for menu choices
        reset_session/0  — clears all dynamic facts
```

---

## 10. How to Extend the System

### Adding a New Diagnosis

**Step 1: Write the diagnosis rule**
```prolog
diagnosis(my_new_problem, CF) :-
    check(symptom_one, yes, 0.85, C1),
    check(symptom_two, yes, 0.70, C2),
    combine_cf(C1, C2, CF).
```

**Step 2: Write the solution**
```prolog
solution(my_new_problem, [
  "STEP 1 | Do this first",
  "STEP 2 | Then do this",
  "STEP 3 | Finally do this"
]).
```

**Step 3: Add a friendly name**
```prolog
friendly_name(my_new_problem, "My New Problem Display Name").
```

**Step 4: Add symptom questions** (only for new symptoms)
```prolog
symptom_question(symptom_one,
    "Is symptom one visible or happening?").
symptom_question(symptom_two,
    "Is symptom two also present?").
```

**Step 5: Add to a category**
```prolog
% Edit the appropriate category_names clause:
category_names(4, [app_crash, driver_conflict, disk_full,
                   missing_runtime, my_new_problem]).  % ← added here
```

### Adding a New Category

```prolog
% Add a new category_names clause:
category_names(8, [my_cat_diag1, my_cat_diag2]).

% Add to the menu in print_menu/0:
format("   [8]  My New Category~n"),

% Add a dispatcher clause:
run_category(8) :-
    !,
    category_names(8, Names),
    run_diagnoses(Names, Results),
    print_results(Results).
```

### Adjusting Confidence Weights

Weights (0.0–1.0) represent how strongly a symptom supports a diagnosis.

| Weight | Meaning |
|--------|---------|
| 0.95 | Almost definitive symptom |
| 0.80 | Strong indicator |
| 0.65 | Moderate indicator |
| 0.50 | Weak indicator |
| 0.30 | Very weak / coincidental |

### Changing the Confidence Threshold

```prolog
% Default: diagnoses below 30% are hidden
cf_threshold(0.30).

% Change to 20% to show more (less certain) results:
cf_threshold(0.20).

% Change to 50% to show only high-confidence results:
cf_threshold(0.50).
```

---

## 11. Example Session Walkthrough

**Scenario: User's Wi-Fi won't connect but Ethernet works**

```
  Your choice: 1.

  Running diagnostic...

  ──────────────────────────────────────────────────────────────
  Q: Does ping 8.8.8.8 fail? (raw IP reachability test)
  ──────────────────────────────────────────────────────────────
  Your answer  [yes / no / unknown] : no.

  ──────────────────────────────────────────────────────────────
  Q: Is internet noticeably slow (pages take a very long time)?
  ──────────────────────────────────────────────────────────────
  Your answer  [yes / no / unknown] : no.

  ──────────────────────────────────────────────────────────────
  Q: Is Wi-Fi failing to connect or authenticate to the AP?
  ──────────────────────────────────────────────────────────────
  Your answer  [yes / no / unknown] : yes.

  ──────────────────────────────────────────────────────────────
  Q: Does a wired Ethernet connection work when Wi-Fi does not?
  ──────────────────────────────────────────────────────────────
  Your answer  [yes / no / unknown] : yes.

  1 diagnosis found (sorted by confidence):

  ══════════════════════════════════════════════════════════════
  DIAGNOSIS #1
  ──────────────────────────────────────────────────────────────
  Problem    : Wi-Fi Connection Problem
  Confidence : 97%  ★★★★★  [VERY HIGH]
  ══════════════════════════════════════════════════════════════

  RECOMMENDED FIX STEPS:
  ──────────────────────────────────────────────────────────────
   STEP 1 | Forget Wi-Fi network and reconnect (enter password again)
   STEP 2 | Disable then re-enable Wi-Fi adapter in Device Manager
   ...
```

**What happened internally:**
1. `run_category(1)` called `run_diagnoses` with all 6 network diagnosis names
2. `diagnosis(wifi_problem, CF)` fired: checked `wifi_not_connecting=yes` → C1=0.85, `ethernet_works=yes` → C2=0.75
3. `combine_cf(0.85, 0.75, CF)` → CF = 0.85 + 0.75×(1−0.85) = **0.9625**
4. `diagnosis(no_internet, CF)` fired: `ping_ip_fails=no` → C1=−0.90, so CF ended negative → filtered out
5. Only `wifi_problem` met the 0.30 threshold → shown to user

---

## 12. Troubleshooting the System Itself

### "ERROR: Unknown procedure: run/0"
→ The file did not load. Check:
```prolog
?- [expert_system].   % Load manually
?- run.               % Then run
```

### "Syntax error" on load
→ Check that the `.pl` file is complete (not truncated).
→ Run: `swipl -g halt expert_system.pl` — errors print on load.

### "My answer isn't being accepted"
→ Make sure you type a **full stop** after your answer: `yes.` not `yes`

### "No diagnosis found" even for obvious problems
→ Answer `unknown.` instead of guessing `no.` — unknown contributes 0 CF,
  whereas a wrong `no.` actively reduces confidence.

### Session gives wrong results after testing
→ Use option `R.` at the main menu to reset all stored answers.

---

## Quick Reference Card

```
START:    swipl -g run expert_system.pl

MENU:     1-7  = specific category
          8    = full scan all categories
          H.   = help
          R.   = reset session
          Q.   = quit

ANSWERS:  yes.  /  no.  /  unknown.
          (always include the full stop!)

CF:       0.97 = 97%  ★★★★★  Very High
          0.80 = 80%  ★★★★☆  High
          0.65 = 65%  ★★★☆☆  Moderate
          0.50 = 50%  ★★☆☆☆  Low-Moderate
          0.35 = 35%  ★☆☆☆☆  Low
          <0.30       (hidden — below threshold)
```

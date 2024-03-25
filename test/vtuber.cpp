#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ncurses.h>

#define NUM_HISTORY 100
#define NUM_IF_REGS 32
#define NUM_STAGES 5

//Global variables
char** inst_contents;
char** timebuffer;
int history_num = 0;
int echo_data = 1;
WINDOW *if_win; //window for instruction fetch stage

//Function to initialize NCurses window
void init_ncurses() {
    initscr();
    cbreak();
    noecho();
    refresh();
  
    //Initialize windows
    if_win = newwin(10, 50, 0, 0);
    box(if_win, 0, 0);
    mvwprintw(if_win, 1, 1, "IF Stage:");
    wrefresh(if_win);
}

//Function to simulate instruction fetch
char* fetch_instruction() {
    //simulated function to fetch instructions
    // return dummy string
    return "ADD $r1, $r2, $r3";
}

// Main Function
int main() {
    //Initialize NCurses
    init_ncurses();

    // Main loop to visual debugging
    while (1) {
        // Fetch instruction
        char* instruction = fetch_instruction();

        // Update IF stage display
        update_if_display(instruction);

        //Pause for visulaization
        sleep(1);
    }

    // End Ncurses
    endwin();

    return 0;
}

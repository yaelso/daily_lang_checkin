#!/bin/bash

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Determine the directory where the script is located
DIR="$(dirname "$(realpath "$0")")"

# File to store the data in the same directory as the script
DATA_FILE="$DIR/.daily_resources_data"

# Initialize the data file if it doesn't exist
if [ ! -f "$DATA_FILE" ]; then
    touch "$DATA_FILE"
fi

# Function to display the data for a selected language
display_data() {
    local lang="$1"
    if ! grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo
        echo -e "\n${RED}Language '$lang' not found.${RESET}\n"
        return
    fi
    awk -v lang="$lang" '/^\[/{p=0} $0 == "[" lang "]" {p=1} p' "$DATA_FILE" | {
        read -r line
        if [[ -z $line ]]; then
            echo
            echo -e "\n${YELLOW}No current resources for $lang.${RESET}\n"
        else
            echo -e "\n${BLUE}$line${RESET}"
            while read -r line; do
                if [[ $line =~ ^\[.*\]$ ]]; then
                    break
                fi
                echo -e "\n$line"
            done
        fi
    }
}

# Function to add a new language
add_language() {
    echo
    echo -e "\n>> Enter the name of the new language (or type 'back' to return to the menu):"
    echo
    read -r lang
    if [[ "$lang" == "back" ]]; then
        echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
        return
    fi
    if grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo
        echo -e "\n${RED}Language already exists.${RESET}\n"
    else
        echo
        echo ">> Enter the categories for $lang (comma-separated, e.g., characters,vocab,grammar) (or type 'back' to return to the menu):"
        read -r categories
        if [[ "$categories" == "back" ]]; then
            echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
            return
        fi
        echo -e "\n[$lang]" >> "$DATA_FILE"
        echo
        echo "Daily Resources:" >> "$DATA_FILE"
        echo
        for category in ${categories//,/ }; do
            echo "$category goal: 0" >> "$DATA_FILE"
        done
        echo -e "\n${GREEN}Language '$lang' added with categories: $categories.${RESET}\n"
    fi
}

# Function to list all languages
list_languages() {
    if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
        echo
        echo -e "\n${YELLOW}No current languages.${RESET}\n"
    else
        echo -e "\n${BLUE}Current languages:${RESET}\n"
        grep -o '^\[.*\]$' "$DATA_FILE" | sed 's/[\[\]]//g'
        echo
    fi
    echo
}

# Function to add a new resource to a selected language
add_resource() {
    local lang="$1"
    if ! grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo
        echo -e "\n${RED}Language '$lang' not found.${RESET}\b"
        return
    fi
    echo
    echo -e "\n>> Enter a new daily resource for $lang (or type 'back' to return to the menu):"
    echo
    read -r resource
    if [[ "$resource" == "back" ]]; then
        echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
        return
    fi
    awk -v lang="$lang" -v res="$resource" '
        $0 == "[" lang "]" {print; getline; print; print "- " res; next}
        1' "$DATA_FILE" > tmpfile && mv tmpfile "$DATA_FILE"
    echo -e "\n${GREEN}Resource added.${RESET}\n"
    echo
}

# Function to update the goals for a selected language
update_goal() {
    local lang="$1"
    if ! grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo
        echo -e "\n${RED}Language '$lang' not found.${RESET}\n"
        return
    fi
    echo
    echo -e "\n>> Enter the category to update (or type 'back' to return to the menu):"
    read -r category
    echo
    if [[ "$category" == "back" ]]; then
        echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
        return
    fi
    echo -e "\n>> Enter the new goal count for $category (or type 'back' to return to the menu):"
    read -r count
    echo
        if [[ "$count" == "back" ]]; then
        echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
        return
    fi

    awk -v lang="$lang" -v category="$category" -v count="$count" '
        $0 == "[" lang "]" {inLang=1}
        inLang && $1 == category {print category " goal: " count; inLang=0; next}
        {print}
    ' "$DATA_FILE" > tmpfile && mv tmpfile "$DATA_FILE"
    echo -e "\n${GREEN}Goal updated.${RESET}\n"
    echo
}

# Main menu
while true; do
    echo -e "=================================="
    echo -e "\n${UNDERLINE}Select an option:${RESET}"
    echo
    echo "1. Display Daily Resources and Goals"
    echo "2. Add a Daily Resource"
    echo "3. Update Goals"
    echo "4. Add a New Language"
    echo "5. List All Languages"
    echo "6. Exit"
    echo
    read -r option

    case $option in
        1)
            if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
                echo -e "\n${YELLOW}No current languages.${RESET}\n"
            else
                echo -e "\n>> Enter the language (or type 'back' to return to the menu):"
                echo
                read -r lang
                if [[ "$lang" == "back" ]]; then
                    echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
                else
                    display_data "$lang"
                fi
            fi
            ;;
        2)
            if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
                echo -e "\n${YELLOW}No current languages.${RESET}\n"
            else
                echo -e "\n>> Enter the language (or type 'back' to return to the menu):"
                echo
                read -r lang
                if [[ "$lang" == "back" ]]; then
                    echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
                else
                    add_resource "$lang"
                fi
            fi
            ;;
        3)
            if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
                echo -e "\n${YELLOW}No current languages.${RESET}\n"
            else
                echo -e "\n>> Enter the language (or type 'back' to return to the menu):"
                echo
                read -r lang
                if [[ "$lang" == "back" ]]; then
                    echo -e "\n${YELLOW}Returning to the menu.${RESET}\n"
                else
                    update_goal "$lang"
                fi
            fi
            ;;
        4)
            add_language
            ;;
        5)
            list_languages
            ;;
        6)
            echo -e "\nExiting...\n"
            break
            ;;
        *)
            echo -e "\n${RED}Invalid option. Please choose 1, 2, 3, 4, 5, or 6.${RESET}\n"
            ;;
    esac
done

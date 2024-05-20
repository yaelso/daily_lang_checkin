#!/bin/bash

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
        echo -e "\nLanguage '$lang' not found.\n"
        return
    fi
    awk -v lang="$lang" '/^\[/{p=0} $0 == "[" lang "]" {p=1} p' "$DATA_FILE" | {
        read -r line
        if [[ -z $line ]]; then
            echo -e "\nNo current resources for $lang.\n"
        else
            echo -e "\n$line"
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
    echo -e "\nEnter the name of the new language:"
    read -r lang
    if grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo -e "\nLanguage already exists.\n"
    else
        echo "Enter the categories for $lang (comma-separated, e.g., characters,vocab,grammar):"
        read -r categories
        echo -e "\n[$lang]" >> "$DATA_FILE"
        echo
        echo "Daily Resources:" >> "$DATA_FILE"
        echo
        for category in ${categories//,/ }; do
            echo "$category goal: 0" >> "$DATA_FILE"
        done
    fi
}

# Function to list all languages
list_languages() {
    if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
        echo -e "\nNo current languages.\n"
    else
        echo -e "\nCurrent languages:\n"
        grep -o '^\[.*\]$' "$DATA_FILE" | sed 's/[\[\]]//g'
        echo
    fi
}

# Function to add a new resource to a selected language
add_resource() {
    local lang="$1"
    if ! grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo -e "\nLanguage '$lang' not found.\b"
        return
    fi
    echo -e "\nEnter a new daily resource for $lang:"
    read -r resource
    awk -v lang="$lang" -v res="$resource" '
        $0 == "[" lang "]" {print; getline; print; print "- " res; next}
        1' "$DATA_FILE" > tmpfile && mv tmpfile "$DATA_FILE"
    echo -e "\nResource added.\n"
}

# Function to update the goals for a selected language
update_goal() {
    local lang="$1"
    if ! grep -q "^\[$lang\]$" "$DATA_FILE"; then
        echo -e "\nLanguage '$lang' not found.\n"
        return
    fi
    echo -e "\nEnter the category to update:"
    read -r category
    echo -e "\nEnter the new goal count for $category:"
    read -r count

    awk -v lang="$lang" -v category="$category" -v count="$count" '
        $0 == "[" lang "]" {inLang=1}
        inLang && $1 == category {print category " goal: " count; inLang=0; next}
        {print}
    ' "$DATA_FILE" > tmpfile && mv tmpfile "$DATA_FILE"
    echo -e "\nGoal updated.\n"
}

# Main menu
while true; do
    echo -e "\nSelect an option:"
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
                echo -e "\nNo current languages.\n"
            else
                echo -e "\nEnter the language:"
                read -r lang
                display_data "$lang"
            fi
            ;;
        2)
            if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
                echo -e "\nNo current languages.\n"
            else
                echo -e "\nEnter the language:"
                read -r lang
                add_resource "$lang"
            fi
            ;;
        3)
            if ! grep -q '^\[.*\]$' "$DATA_FILE"; then
                echo -e "\nNo current languages.\n"
            else
                echo -e "\nEnter the language:"
                read -r lang
                update_goal "$lang"
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
            echo -e "\nInvalid option. Please choose 1, 2, 3, 4, 5, or 6.\n"
            ;;
    esac
done

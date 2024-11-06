#!/bin/bash

# Source the inputs.sh file to access variables
source inputs.sh

# Function to extract key-value pairs from the map string
extract_vars() {
    local prefix=$1
    local map_string=$2

    # Remove outer "map[" and trailing "]"
    map_string="${map_string#map[}"
    map_string="${map_string%]}"

    # Convert the map string into an array, splitting on spaces
    IFS=' ' read -ra kv_pairs <<< "$map_string"

    # Process each key-value pair
    for kv in "${kv_pairs[@]}"; do
        # Split key=value
        IFS=':' read -r key value <<< "$kv"
        
        # Remove commas and quotes from values, if any
        key="${key//,/}"
        value="${value//,/}"
        
        # Replace slashes with underscores in key name and print in desired format
        echo "${prefix}_${key}=\"$value\""
    done
}

# Extract and print variables from $ior and $settings
extract_vars "ior" "$ior"
extract_vars "settings" "$settings"

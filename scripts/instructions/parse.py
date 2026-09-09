"""
Parse instructions from a text file and write them to a structured JSON file.
"""

import json
from pathlib import Path

input_file = Path("instructions.txt")
output_file = Path("instructions.json")


instructions = {}


def main():
    data = input_file.read_text()

    block = {}
    header = []
    addressing = []
    block_idx = 0
    blanks = 0
    for data in data.splitlines():
        if blanks == 2:
            block = {}
            blanks = 0
            block_idx = 0
            header = []
        elif data:
            blanks = 0
        else:
            blanks += 1
            continue

        match block_idx:
            case 0:
                instructions[data] = block
                block_idx += 1
            case 1:
                block["Description"] = data
                block_idx += 1
            case 2:
                block["Operation"] = data
                block_idx += 1
            case 3:
                if header:
                    block["Status"] = {k: v for k, v in zip(header, data.split("\t"))}
                    block_idx += 1
                    header = []
                else:
                    header = data.split("\t")
            case 4:
                if header:
                    addressing.append({k: v for k, v in zip(header, data.split("\t"))})
                else:
                    header = data.split("\t")
                    addressing = []
                    block["Ops"] = addressing

    with output_file.open("w") as f:
        f.write(json.dumps(instructions, indent=4))


if __name__ == "__main__":
    main()

import argparse
import socket
import struct


def hex_to_stack(string):
    """Prints stack push instructions for a hex string, reversing byte order and padding as needed."""
    reversed_hex = [string[i:i+2] for i in range(0, len(string), 2)][::-1]
    remainder = len(reversed_hex) % 4
    if remainder:
        print("\tpush 0x" + "90" * (4 - remainder) + "".join(reversed_hex[0:remainder]))
    for p in range(remainder, len(reversed_hex), 4):
        print("\tpush 0x" + "".join(reversed_hex[p:p + 4]))


def ip_to_hex(ip):
    """Converts an IP address string to a little-endian hexadecimal integer."""
    packed_ip = socket.inet_aton(ip)
    hex_ip = struct.unpack("<L", packed_ip)[0]
    return hex_ip


def ror(data, shift, size=32):
    """Performs a bitwise rotate-right (ROR) operation on an integer value."""
    shift %= size
    body = data >> shift
    remains = (data << (size - shift)) - (body << size)
    return (body + remains)


def string_to_hash(word):
    """Hashes a string using a custom ROR-based algorithm and returns the hex result."""
    result = 0
    for i in word:
        result = ror(result, 13)
        result += ord(i)
    return hex(result)


def string_to_stack(string):
    """Prints stack push instructions for a string, encoding as hex and reversing byte order."""
    string_hex = string.encode("utf-8").hex()
    reversed_hex = [string_hex[i:i+2] for i in range(0, len(string_hex), 2)][::-1]
    remainder = len(reversed_hex) % 4
    if remainder:
        print("\tpush 0x" + "00" * (4 - remainder) + "".join(reversed_hex[0:remainder]))
    for p in range(remainder, len(reversed_hex), 4):
        print("\tpush 0x" + "".join(reversed_hex[p:p + 4]))


def print_all_hex_bytes(var_name="buf"):
    """Prints all possible hex byte values as a Python bytes variable assignment."""
    hex_bytes = [f"\\x{b:02x}" for b in range(256)]
    print(f"{var_name} = b\"\"")
    for i in range(0, 256, 16):
        print(f"{var_name} += b\"{''.join(hex_bytes[i:i+16])}\"")


def main():
    parser = argparse.ArgumentParser(description="Stack and hash utilities")
    subparsers = parser.add_subparsers(dest="command")

    parser_hex2stack = subparsers.add_parser("hex2stack")
    parser_hex2stack.add_argument("hex_string")

    parser_ip2stack = subparsers.add_parser("ip2stack")
    parser_ip2stack.add_argument("ip")

    parser_string2hash = subparsers.add_parser("string2hash")
    parser_string2hash.add_argument("word")

    parser_string2stack = subparsers.add_parser("string2stack")
    parser_string2stack.add_argument("string")

    parser_allchars = subparsers.add_parser("allchars")
    parser_allchars.add_argument("var_name", nargs="?", default="buf")

    args = parser.parse_args()

    if args.command == "hex2stack":
        hex_to_stack(args.hex_string)
    elif args.command == "ip2stack":
        hex_ip = ip_to_hex(args.ip)
        print(f"push 0x{hex_ip:08x}\t\t; {args.ip}")
    elif args.command == "string2hash":
        result = string_to_hash(args.word)
        print(result)
    elif args.command == "string2stack":
        string_to_stack(args.string)
    elif args.command == "allchars":
        print_all_hex_bytes(args.var_name)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
FileWarden

FileWarden is a lightweight Bash utility for Linux that protects critical files by applying the **immutable attribute** (`chattr +i`).  
Once a file is made immutable, it cannot be modified, deleted, or renamed — even by root — until the flag is removed.

This makes FileWarden a useful last-line defense against accidental changes, misbehaving scripts, or malicious tampering.

Features
- Prompt for up to 5 file paths interactively.  
- Apply the immutable (+i) flag to each file.  
- Display the attribute state with lsattr so you can confirm protection.  
- Skip missing or invalid files gracefully.  
- Works on any Linux filesystem that supports chattr (e.g., ext4).

Usage
Make the script executable: chmod +x filewarden.sh

Option 1: Interactive mode
Run with no arguments and provide up to 5 file paths when prompted: ./filewarden.sh

Option 2: Pass file paths directly
You can also pass up to 5 file paths as arguments: ./filewarden.sh ~/secrets.txt /etc/hosts /home/user/config.cfg

Confirming immutability

After running FileWarden, check that the immutable flag is set: lsattr /path/to/file.txt

Example output:

----i---------e------- /home/user/file.txt

The i means the file is immutable.

Reverting immutability

To make a file editable again, remove the flag: sudo chattr -i /path/to/file.txt

Requirements
- Linux system with a filesystem that supports file attributes (e.g. ext4).  
- chattr and lsattr (provided by e2fsprogs on most distros).  
- Root privileges (sudo) to modify attributes on most system files.

Legal Disclaimer

FileWarden is provided as is without any warranties, express or implied.  
Use of this script is at your own risk. The authors and distributors of FileWarden are not responsible for **data loss, system instability, or security incidents** resulting from its use.  
Before applying immutable flags, ensure you understand the consequences — improperly locking system files can render your system unbootable. Always test in a safe environment first.

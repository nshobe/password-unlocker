## Password Unlocker
Due to PCI policies we don't allow passwords for users to exist for more than 30 days. Thus, after 30 days of age a password will expire and lock an account. This script is intended to generate a random password and update that account with the new password and email generated credentials. This allows us to keep strict password policies in place, without leaking commonly used reset passwords.

## Compatability
Should work on RHEL6 & 7, as well as Solaris 10. Not tested on Solaris 9 or 11.

## Security
### Any time you're dealing with passwords there are security risks!

In a perfect world, clear text passwords would never be transported, and hashes would only ever be sent TO the keystore, never read FROM the keystore. That said, this is what's been done:

The program operates out of root's home directory, as it should only ever be run as root. It creates two files, both of which get enforced to file mode 600 and owned by root, repeatedly, on every run. If you wanted, you could alter the report file to log under /var/log and put it under rotation or ship it out with your favorite log gatherer (ELK, Splunk, etc), but my default was to assume a semi-hostile environment. If your root's homedir is compromised you likely have larger problems afoot.

Furthermore, if you want to complain that a randomly generated password sent over what ever mailing system an OS uses is insecure, consider that anyone using this is likely replacing a system in which a support staff is resetting passwords to something like "NewPassword01" at a company-wide scale. If you're serious about auth at scale, use something like oauth or ldap and manage it with secure practices.

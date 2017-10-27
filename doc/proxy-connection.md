Proxy connection is a connection type that hides some details from you between you and your target (Raspberry, in this case).

Normally you have to know target device's IP address in order to be able to connect to it. If your target is another location, you have to make some port forwardings in the target network's modem/firewall. You also have to assign static IP address to your target.

If you setup https://github.com/aktos-io/link-with-server/ on the target, you don't have to assign a static IP, you don't have to make port forwardings and you don't have to know the public IP address of the target network. Instead, it will connect to your server, drop its SSHD port on the server so you may connect to server:target_port and voila! You are on your target's shell.

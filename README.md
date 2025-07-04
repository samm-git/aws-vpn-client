# aws-vpn-client-docker

> [!IMPORTANT]
> This repository is largely simply packaging other authors' work!
> 
> ## Credits
> 
> ### [samm-git/aws-vpn-client](https://github.com/samm-git/aws-vpn-client)
> 
> Alex Samorukov is the mastermind behind this implementation. He figured out how AWS patches the openvpn client and
> created the first implementations. Be sure to read his [blog](https://smallhacks.wordpress.com/2020/07/08/aws-client-vpn-internals/)
> on for more details.
> 
> ### [botify-labs/aws-vpn-client](https://github.com/botify-labs/aws-vpn-client)
> 
> Botify Labs maintains the `.patch` files for more recent versions of OpenVPN than what are available originally
> in Alex's repository.
>
> ### [kpalang/aws-vpn-client-docker](https://github.com/kpalang/aws-vpn-client-docker)
> Kaur Palang packaged the work of Alex Samorukov and Botify Labs into a Docker container format,
> making OpenVPN compatible with AWS VPN SAML while providing consistent deployment across environments.
>
> ### [kpalang/aws-vpn-client-docker](https://github.com/kpalang/aws-vpn-client-docker)
> Papuna Gagnidze packaged the work of Alex Samorukov, Botify Labs and Kaur Palang into a Docker container format,
> and embeds the OpenVPN profile directly into the Docker image at build time instead of using runtime volume mounts,
> avoiding SELinux context conflicts while maintaining security isolation. Tested on Fedora Asahi Linux.

---

This fork adds a makefile and describes the possibility to start VPN Global from the terminal.

## How to use

### Build the container yourself
1. Clone this repository
2. Download your AWS VPN client profile into a directory
3. Place your AWS VPN client profile (`cvpn-endpoint-*.ovpn`, or `vpn.conf`) in the same directory as the Dockerfile, renaming it to `profile.ovpn`
4. Run `make build`

## Use it global
you can add this to your `.bashrc` or `.bash_aliases`
```bash
vpn() {
  make -C YOUR_PHAT/aws-vpn-client-docker $@ --no-print-directory
}
```
Replace `YOUR_PHAT` with the right phat.

Save and run `source .bashrc` or `source .bash_aliases` to reload the file.

To start vpn run `vpn run`, `vpn start` or `vpn 1`. More comands you can see with `vpn` or `vpn help` 


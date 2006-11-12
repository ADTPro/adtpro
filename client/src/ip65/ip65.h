/* network configuration - call ip65_init() after setting */
extern unsigned char ip65_mac[6];
extern unsigned char ip65_ip[4];
extern unsigned char ip65_netmask[4];
extern unsigned char ip65_gateway[4];
extern unsigned char ip65_dns[4];

/* initialize stack - setup network configuration first */
char ip65_init(void);

/* lookup ip address, copies mac address */
char ip65_arp_lookup(unsigned char *ip, unsigned char *mac);

/* lookup dns name, copies ip address */
char ip65_dns_lookup(unsigned char *name, unsigned char *ip);

/* add an icmp listener */
char ip65_icmp_listen(unsigned char type, void (*handler)(unsigned int, unsigned char *));

/* add an udp listener */
char ip65_udp_listen(unsigned short port, void (*handler)(unsigned int, unsigned char *));

/* add a tcp listener */
char ip65_tcp_listen(unsigned short port, void (*handler)(unsigned int, unsigned char *));

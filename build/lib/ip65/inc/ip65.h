#ifndef _IP65_H
#define _IP65_H

#include <stdint.h>
#include <stdbool.h>

// Ethernet driver initialization parameter values
//
#if defined(__APPLE2__)
#define ETH_INIT_DEFAULT 3  // Apple II slot number
#elif defined(__ATARI__)
#define ETH_INIT_DEFAULT 8  // ATARI PBI device ID
#else
#define ETH_INIT_DEFAULT 0  // Unused
#endif

// Initialize the IP stack
//
// This calls the individual protocol & driver initializations, so this is
// the only *_init routine that must be called by a user application,
// except for dhcp_init which must also be called if the application
// is using DHCP rather than hardcoded IP configuration.
//
// Inputs: eth_init: Ethernet driver initialization parameter
// Output: true if there was an error, false otherwise
//
bool __fastcall__ ip65_init(uint8_t eth_init);

// Access to Ethernet configuration
//
// Access to the two items below is only valid after ip65_init returned false.
//
extern uint8_t  cfg_mac[6]; // MAC address of local machine
extern char     eth_name[]; // Zero terminated string containing Ethernet driver name

// Error codes
//
#define IP65_ERROR_PORT_IN_USE                   0x80
#define IP65_ERROR_TIMEOUT_ON_RECEIVE            0x81
#define IP65_ERROR_TRANSMIT_FAILED               0x82
#define IP65_ERROR_TRANSMISSION_REJECTED_BY_PEER 0x83
#define IP65_ERROR_NAME_TOO_LONG                 0x84
#define IP65_ERROR_DEVICE_FAILURE                0x85
#define IP65_ERROR_ABORTED_BY_USER               0x86
#define IP65_ERROR_LISTENER_NOT_AVAILABLE        0x87
#define IP65_ERROR_CONNECTION_RESET_BY_PEER      0x89
#define IP65_ERROR_CONNECTION_CLOSED             0x8A
#define IP65_ERROR_MALFORMED_URL                 0xA0
#define IP65_ERROR_DNS_LOOKUP_FAILED             0xA1

// Last error code
//
extern uint8_t ip65_error;

// Convert error code into a string describing the error
//
// The pointer returned is a static string, which mustn't be modified.
//
// Inputs: err_code: Error code
// Output: Zero terminated string describing the error
//
char* __fastcall__ ip65_strerror(uint8_t err_code);

// Main IP polling loop
//
// This routine should be periodically called by an application at any time
// that an inbound packet needs to be handled.
// It is 'non-blocking', i.e. it will return if there is no packet waiting to be
// handled. Any inbound packet will be handed off to the appropriate handler.
//
// Inputs: None
// Output: true if no packet was waiting or packet handling caused error, false otherwise
//
bool ip65_process(void);

// Generate a 'random' 16 bit word
//
// Entropy comes from the last ethernet frame, counters, and timer.
//
// Inputs: None
// Output: Pseudo-random 16 bit number
//
uint16_t ip65_random_word(void);

// Convert 4 octets (IP address, netmask) into a string representing a dotted quad
//
// The string is returned in a statically allocated buffer, which subsequent calls
// will overwrite.
//
// Inputs: quad: IP address
// Output: Zero terminated string containing dotted quad (e.g. "192.168.1.0")
//
char* __fastcall__ dotted_quad(uint32_t quad);

// Convert a string representing a dotted quad (IP address, netmask) into 4 octets
//
// Inputs: quad: Zero terminated string containing dotted quad (e.g. "192.168.1.0"),
//               to simplify URL parsing, a ':' or '/' can also terminate the string.
// Output: IP address, 0 on error
//
uint32_t __fastcall__ parse_dotted_quad(char* quad);

// Minimal DHCP client implementation
//
// IP addresses are requested from a DHCP server (aka 'leased') but are not renewed
// or released. Although this is not correct behaviour according to  the DHCP RFC,
// this works fine in practice in a typical home network environment.
//
// Inputs: None (although ip65_init should be called first)
// Output: false if IP config has been sucesfully obtained and cfg_ip, cfg_netmask,
//               cfg_gateway and cfg_dns will be set per response from dhcp server.
//               dhcp_server will be set to address of server that provided configuration.
//         true if there was an error
//
bool dhcp_init(void);

// Access to IP configuration
//
// The five items below will be overwritten if dhcp_init is called.
//
extern uint32_t cfg_ip;         // IP address of local machine
extern uint32_t cfg_netmask;    // Netmask of local network
extern uint32_t cfg_gateway;    // IP address of router on local network
extern uint32_t cfg_dns;        // IP address of DNS server to use
extern uint32_t dhcp_server;    // Address of DHCP server that config was obtained from

// Resolve a string containing a hostname (or a dotted quad) to an IP address
//
// Inputs: hostname: Zero terminated string containing either a DNS hostname
//                   (e.g. "host.example.com") or an address in "dotted quad"
//                   format (e.g. "192.168.1.0")
// Output: IP address of the hostname, 0 on error
//
uint32_t __fastcall__ dns_resolve(const char* hostname);

// Send a ping (ICMP echo request) to a remote host, and wait for a response
//
// Inputs: dest: Destination IP address
// Output: 0 if no response, otherwise time (in miliseconds) for host to respond
//
uint16_t __fastcall__ icmp_ping(uint32_t dest);

// Add a UDP listener
//
// Inputs: port:     UDP port to listen on
//         callback: Vector to call when UDP packet arrives on specified port
// Output: true if too may listeners already installed, false otherwise
//
bool __fastcall__ udp_add_listener(uint16_t port, void (*callback)(void));

// Remove a UDP listener
//
// Inputs: port: UDP port to stop listening on
// Output: false if handler found and removed,
//         true if handler for specified port not found
//
bool __fastcall__ udp_remove_listener(uint16_t port);

// Access to received UDP packet
//
// Access to the four items below is only valid in the context of a callback
// added with udp_add_listener.
//
extern uint8_t  udp_recv_buf[1476];        // Buffer with data received
       uint16_t udp_recv_len(void);        // Length of data received
       uint32_t udp_recv_src(void);        // Source IP address
       uint16_t udp_recv_src_port(void);   // Source port

// Send a UDP packet
//
// If the correct MAC address can't be found in the ARP cache then
// an ARP request is sent - and the UDP packet is NOT sent. The caller
// should wait a while calling ip65_process (to allow time for an ARP
// response to arrive) and then call upd_send again. This behavior
// makes sense as a UDP packet may get lost in transit at any time
// so the caller should to be prepared to resend it after a while
// anyway.
//
// Inputs: buf:       Pointer to buffer containing data to be sent
//         len:       Length of data to send (exclusive of any headers)
//         dest:      Destination IP address
//         dest_port: Destination port
//         src_port:  Source port
// Output: true if an error occured, false otherwise
//
bool __fastcall__ udp_send(const uint8_t* buf, uint16_t len, uint32_t dest,
                           uint16_t dest_port, uint16_t src_port);

// Listen for an inbound TCP connection
//
// This is a 'blocking' call, i.e. it will not return until a connection has been made.
//
// Inputs: port:     TCP port to listen on
//         callback: Vector to call when data arrives on this connection
//                   buf: Pointer to buffer with data received
//                   len: -1 on close, otherwise length of data received
// Output: IP address of the connected client, 0 on error
//
uint32_t __fastcall__ tcp_listen(uint16_t port,
                                 void __fastcall__ (*callback)(const uint8_t* buf,
                                                               int16_t len));

// Make outbound TCP connection
//
// Inputs: dest:      Destination IP address
//         dest_port: Destination port
//         callback:  Vector to call when data arrives on this connection
//                    buf: Pointer to buffer with data received
//                    len: -1 on close, otherwise length of data received
// Output: true if an error occured, false otherwise
//
bool __fastcall__ tcp_connect(uint32_t dest, uint16_t dest_port,
                              void __fastcall__ (*callback)(const uint8_t* buf,
                                                            int16_t len));

// Close the current TCP connection
//
// Inputs: None
// Output: true if an error occured, false otherwise
//
bool tcp_close(void);

// Send data on the current TCP connection
//
// Inputs: buf: Pointer to buffer containing data to be sent
//         len: Length of data to send (up to 1460 bytes)
// Output: true if an error occured, false otherwise
//
bool __fastcall__ tcp_send(const uint8_t* buf, uint16_t len);

// Send an empty ACK packet on the current TCP connection
//
// Inputs: None
// Output: true if an error occured, false otherwise
//
bool tcp_send_keep_alive(void);

// Query an SNTP server for current UTC time
//
// Inputs: SNTP server IP address
// Output: The number of seconds since 00:00 on Jan 1 1900 (UTC), 0 on error
//
uint32_t __fastcall__ sntp_get_time(uint32_t server);

// Download a file from a TFTP server and provide data to user supplied vector
//
// Inputs: server:   IP address of server to receive file from
//         name:     Zero terminated string containing the name of file to download
//         callback: Vector to call once for each 512 byte packet received
//                   buf: Pointer to buffer containing data received
//                   len: 512 if buffer is full, otherwise number of bytes
//                        in the buffer
// Output: true if an error occured, false otherwise
//
bool __fastcall__ tftp_download(uint32_t server, const char* name,
                                void __fastcall__ (*callback)(const uint8_t* buf,
                                                              uint16_t len));

// Download a file from a TFTP server and provide data to specified memory location
//
// Inputs: server: IP address of server to receive file from
//         name:   Zero terminated string containing the name of file to download
//         buf:    Pointer to buffer containing data received
// Output: Length of data received, 0 on error
//
uint16_t __fastcall__ tftp_download_to_memory(uint32_t server, const char* name,
                                              const uint8_t* buf);

// Upload a file to a TFTP server with data retrieved from user supplied vector
//
// Inputs: server:   IP address of server to send file to
//         name:     Zero terminated string containing the name of file to upload
//         callback: Vector to call once for each 512 byte packet to be sent
//                   buf: Pointer to buffer containing data to be sent
//                   Output: 512 if buffer is full, otherwise number of bytes
//                           in the buffer
// Output: true if an error occured, false otherwise
//
bool __fastcall__ tftp_upload(uint32_t server, const char* name,
                              uint16_t __fastcall__ (*callback)(const uint8_t* buf));

// Upload a file to a TFTP server with data retrieved from specified memory location
//
// Inputs: server: IP address of server to send file to
//         name:   Zero terminated string containing the name of file to upload
//         buf:    Pointer to buffer containing data to be sent
//         len:    Length of data to be sent
// Output: true if an error occured, false otherwise
//
bool __fastcall__ tftp_upload_from_memory(uint32_t server, const char* name,
                                          const uint8_t* buf, uint16_t len);

// Parse an HTTP URL into a form that makes it easy to retrieve the specified resource
//
// On success the variables url_ip, url_port and url_selector (see below) are valid.
//
// Inputs: url: Zero (or ctrl char) terminated string containing the URL
// Output: true if an error occured, false otherwise
//
bool __fastcall__ url_parse(const char* url);

// Access to parsed HTTP URL
//
// Access to the three items below is only valid after url_parse returned false.
//
extern uint32_t url_ip;         // IP address of host in URL
extern uint16_t url_port;       // Port number of URL
extern char*    url_selector;   // Zero terminated string containing selector part of URL

// Download a resource specified by an HTTP URL
//
// The URL mustn't be longer than 1400 chars. The buffer is temporarily used to hold the
// generated HTTP request so it should have a length of at least 1460 bytes. On success
// the resource is zero terminated.
//
// Inputs: url: Zero (or ctrl char) terminated string containing the URL
//         buf: Pointer to a buffer that the resource will be downloaded into
//         len: Length of buffer
// Output: Length of resource downloaded, 0 on error
//
uint16_t __fastcall__ url_download(const char* url, const uint8_t* buf, uint16_t len);

// Start an HTTP server
//
// This routine will stay in an endless loop that is broken only if user press the abort key.
//
// Inputs: port:     TCP port to listen on
//         callback: Vector to call for each inbound HTTP request
//                   client: IP address of the client that sent the request
//                   method: Zero terminated string containing the HTTP method
//                   path:   Zero terminated string containing the HTTP path
// Output: None
//
void __fastcall__ httpd_start(uint16_t port,
                              void __fastcall__ (*callback)(uint32_t client,
                                                            const char* method,
                                                            const char* path));

// HTTP response types
//
#define HTTPD_RESPONSE_NOHEADER 0   // No HTTP response header
#define HTTPD_RESPONSE_200_TEXT 1   // HTTP Code: 200 OK, Content Type: 'text/text'
#define HTTPD_RESPONSE_200_HTML 2   // HTTP Code: 200 OK, Content Type: 'text/html'
#define HTTPD_RESPONSE_200_DATA 3   // HTTP Code: 200 OK, Content Type: 'application/octet-stream'
#define HTTPD_RESPONSE_404      4   // HTTP Code: 404 Not Found
#define HTTPD_RESPONSE_500      5   // HTTP Code: 500 System Error

// Send HTTP response
//
// Calling httpd_send_response is only valid in the context of a httpd_start callback.
// For the response types HTTPD_RESPONSE_404 and HTTPD_RESPONSE_500 'buf' is ignored.
// With the response type HTTPD_RESPONSE_NOHEADER it's possible to add more content to
// an already sent HTTP response.
//
// Inputs: response_type: Value describing HTTP code and content type in response header
//         buf:           Pointer to buffer with HTTP response content
//         len:           Length of buffer with HTTP response content
// Output: None
//
void __fastcall__ httpd_send_response(uint8_t response_type,
                                      const uint8_t* buf, uint16_t len);

// Retrieve the value of a variable defined in the previously received HTTP request
//
// Calling http_get_value is only valid in the context of a httpd_start callback.
// Only the first letter in a variable name is significant. E.g. if a querystring contains
// the variables 'a','alpha' and 'alabama', then only the first one will be retrievable.
//
// Inputs: name: Variable to retrieve
// Output: Variable value (zero terminated string) if variable exists, null otherwise.
//
char* __fastcall__ http_get_value(char name);

// Get number of milliseconds since initialization
//
// Inputs: None
// Output: Current number of milliseconds
//
uint16_t timer_read(void);

// Check if specified period of time has passed yet
//
// Inputs: time: Number of milliseconds we are willing to wait for
// Output: true if timeout occured, false otherwise
//
bool __fastcall__ timer_timeout(uint16_t time);

// Check whether the abort key is being pressed
//
// Inputs: None
// Output: true if abort key pressed, false otherwise
//
bool input_check_for_abort_key(void);

// Control abort key
//
// Control if the user can abort blocking functions with the abort key
// (making them return IP65_ERROR_ABORTED_BY_USER). Initially the abort
// key is enabled.
//
// Inputs: enable: false to disable the key, true to enable the key
// Output: None
//
void __fastcall__ input_set_abort_key(bool enable);

// Access to actual abort key code
//
extern uint8_t abort_key;

#endif

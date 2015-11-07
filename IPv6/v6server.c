/*
 * vim:sw=2 ts=8:noet sta
 *
 *
 * Copyright (c) 1999, 2000, 2001, 2002, 2003 Ariff Abdullah 
 *        (skywizard@MyBSD.org.my) All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *        $MyBSD$
 *
 * Date: Mon Oct 20 20:19:23 MYT 2003
 *   OS: FreeBSD kasumi.MyBSD.org.my 4.7-RELEASE i386
 *
 */

#include <sys/types.h>
#include <sys/uio.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <err.h>

#define SERVER_QUEUE 10

int
main(int argc, char **argv)
{
  struct addrinfo hint, *res, *tmpres;
  struct sockaddr_storage claddr;
  char *server_addr, *server_port;
  int server_fd, client_fd, status;
  char clhost[NI_MAXHOST];
  char clport[NI_MAXSERV];
  char message_buf[4096];
  char server_message_buf[4096 + 128];
  unsigned long connection_count;
  int family;
  socklen_t addrlen;

  if (argc != 3)
    errx(1, "Usage: %s <server ip> <server port>", argv[0]);

  server_addr = argv[1];
  server_port = argv[2];
  bzero(&hint, sizeof(hint));
  hint.ai_flags = AI_PASSIVE;
  hint.ai_family = AF_UNSPEC;
  hint.ai_socktype = SOCK_STREAM;
  if (getaddrinfo(server_addr, server_port, &hint, &res) != 0)
    err(1, "getaddrinfo() error");
  tmpres = res;
  server_fd = -1;
  family = -1;
  while (tmpres) {
    server_fd = socket(tmpres->ai_family, tmpres->ai_socktype, tmpres->ai_protocol);
    if (!(server_fd < 0)) {
      setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, (void *)&status, sizeof(status));
      if (bind(server_fd, tmpres->ai_addr, tmpres->ai_addrlen) == 0) {
	family = tmpres->ai_family;
	break;
      }
      close(server_fd);
    }
    tmpres = tmpres->ai_next;
    server_fd = -1;
  }
  freeaddrinfo(res);
  if (server_fd < 0)
    errx(1, "Failed to bind server socket");
  if (listen(server_fd, SERVER_QUEUE) != 0) {
    warn("listen() failed");
    close(server_fd);
    return 1;
  }
  connection_count = 0;
  switch (family) {
    case AF_INET:
      printf("IPv4 Server on %s Port %s\n", server_addr, server_port);
      break;
    case AF_INET6:
      printf("IPv6 Server on %s Port %s\n", server_addr, server_port);
      break;
    default:
      printf("Unknown Server on %s Port %s\n", server_addr, server_port);
      break;
  }
  for (;;) {
    bzero(&claddr, sizeof(claddr));
    addrlen = sizeof(claddr);
    client_fd = accept(server_fd, (struct sockaddr *)&claddr, &addrlen);
    if (client_fd < 0)
      continue;
    bzero(clhost, sizeof(clhost));
    bzero(clport, sizeof(clport));
    if (getnameinfo((struct sockaddr *)&claddr, addrlen,
	    clhost, sizeof(clhost), clport, sizeof(clport),
	    NI_NUMERICHOST|NI_NUMERICSERV) != 0) {
      warn("getnameinfo() failed");
      continue;
    }
    printf("(%lu) Client connected from %s port %s (Using: ",
	++connection_count, clhost, clport);
    switch (claddr.ss_family) {
      case AF_INET:
	printf("IPv4");
	break;
      case AF_INET6:
	printf("IPv6");
	break;
      default:
	printf("Unknown family type!!");
	break;
    }
    printf(")\n(%lu) Client message: ", connection_count);
    bzero(message_buf, sizeof(message_buf));
    bzero(server_message_buf, sizeof(server_message_buf));
    if (read(client_fd, message_buf, sizeof(message_buf) - 1) < 0)
      warn("Server read() client data failed");
    else {
      printf("%s", message_buf);
      strcpy(server_message_buf, "Server Reply: ");
      if (message_buf[strlen(message_buf) - 1] != '\n') {
	printf("\n");
	strcat(server_message_buf, message_buf);
	strcat(server_message_buf, "\n");
      } else
	strcat(server_message_buf, message_buf);
      if (write(client_fd, server_message_buf, strlen(server_message_buf)) < 0)
	warn("Server write() client data failed");
    }
    printf("<--------------------------->\n");
    close(client_fd);
  }
  /* Not reached */
  close(server_fd);
  return 0;
}

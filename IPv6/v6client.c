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
  char *server_addr, *server_port;
  int server_fd, family;
  char *my_message;
  char message_buf[4096];

  if (argc != 4)
    errx(1, "Usage: %s <server ip> <server port> 'message to send'", argv[0]);

  server_addr = argv[1];
  server_port = argv[2];
  my_message = argv[3];
  if (strlen(my_message) > 1024)
    errx(1, "Message size too long");
  printf("Trying on %s Port %s\n", server_addr, server_port);
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
      if (connect(server_fd, tmpres->ai_addr, tmpres->ai_addrlen) == 0) {
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
    errx(1, "Failed to connect() server socket");
  switch (family) {
    case AF_INET:
      printf("Connected, IPv4\n");
      break;
    case AF_INET6:
      printf("Connected, IPv6\n");
      break;
    default:
      printf("Unknown family type server\n");
      break;
  }
  bzero(message_buf, sizeof(message_buf));
  strcpy(message_buf, my_message);
  strcat(message_buf, "\n");
  write(server_fd, message_buf, strlen(message_buf));
  bzero(message_buf, sizeof(message_buf));
  read(server_fd, message_buf, sizeof(message_buf) - 1);
  printf("%s", message_buf);
  close(server_fd);
  return 0;
}

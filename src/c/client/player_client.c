/*
 * Simple example of parsing and printing JSON using jansson.
 *
 * SYNOPSIS:
 * $ examples/simple_parse
 * Type some JSON > [true, false, null, 1, 0.0, -0.0, "", {"name": "barney"}]
 * JSON Array of 8 elements:
 *   JSON True
 *   JSON False
 *   JSON Null
 *   JSON Integer: "1"
 *   JSON Real: 0.000000
 *   JSON Real: -0.000000
 *   JSON String: ""
 *   JSON Object of 1 pair:
 *     JSON Key: "name"
 *     JSON String: "barney"
 *
 * Copyright (c) 2014 Robert Poor <rdpoor@gmail.com>
 *
 * Jansson is free software; you can redistribute it and/or modify
 * it under the terms of the MIT license. See LICENSE for details.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <jansson.h>
#include <sys/fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define RECV_SIZE (10000)
#define SEND_SIZE (10000)
#define TEAM_NAME ("foo")

/*
 * Parse text into a JSON object. If text is valid JSON, returns a
 * json_t structure, otherwise prints and error and returns null.
 */
json_t *load_json(const char *text) {
	json_t *root;
	json_error_t error;

	root = json_loads(text, 0, &error);

	if (root) {
		return root;
	} else {
		fprintf(stderr, "json error on line %d: %s\n", error.line, error.text);
		return (json_t *) 0;
	}
}

/*
 * Print a prompt and return (by reference) a null-terminated line of
 * text.  Returns NULL on eof or some error.
 */
char *read_line(char *line, int max_chars) {
	printf("Type some JSON > ");
	fflush(stdout);
	return fgets(line, max_chars, stdin);
}

/* ================================================================
 * main
 */

// バッファから1行取り出す。(get string)
// 改行に当たるまで待機します。
char* sgets(int sd, char* line) {
	// 前回改行までに取り出した部分
	static char* read_buf = NULL;
	if (read_buf == NULL) {
		read_buf = malloc(sizeof(char) * RECV_SIZE);
		read_buf[0] = '\0';
	}

	while (1) {
		int e;
		if (strlen(read_buf) != (e = strcspn(read_buf, "\n"))) {
			memset(line, '\0', sizeof(char) * strlen(line));
			strncpy(line, read_buf, (e + 1) - 0);

			// 先頭を取り出す
			char* temp = malloc(sizeof(char) * RECV_SIZE);
			strcpy(temp, strchr(read_buf, '\n') + 1);
			free(read_buf);
			read_buf = temp;
			break;
		}
		char r[99999] = { 0 };


		if ((e = read(sd, r, sizeof(r) * RECV_SIZE)) < 0) {
			perror("recv");
			fflush(0);
			return NULL;
		}

		strcat(read_buf, r);
	}

	return line;
}

void sputs(int sd, char* str) {
	if (write(sd, str, sizeof(char) * strlen(str)) < 0) {
		perror("send");
		return;
	}
}


int main(int argc, char *argv[]) {
	int sd;  //ソケット作成用の変数
	struct sockaddr_in addr;  //サーバ接続用の変数
	char *recv_json;  //受信データ格納用の変数
	recv_json = malloc(sizeof(char) * RECV_SIZE);

	// IPv4 TCP のソケットを作成する
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("socket");
		return -1;
	}

	// 送信先アドレスとポート番号を設定する
	addr.sin_family = AF_INET;
	addr.sin_port = htons(20000);
	addr.sin_addr.s_addr = inet_addr("127.0.0.1");
	//addr.sin_addr.s_addr = inet_addr("192.168.11.5");

	// サーバ接続（TCP の場合は、接続を確立する必要がある）
	connect(sd, (struct sockaddr *) &addr, sizeof(struct sockaddr_in));

	// 名前要求
	sgets(sd, recv_json);
	printf("request name: <<<%s>>>\n", recv_json);

	// 名前送信
	char* name_json = malloc(sizeof(name_json) * (SEND_SIZE + 2));
	sprintf(name_json, "{\"team_name\": \"%s\"}\n", TEAM_NAME);
	sputs(sd, name_json);
	free(name_json);

	// 名前確定
	sgets(sd, recv_json);
	printf("defined name: <<<%s>>>", recv_json);

	// 盤面情報
	while (1) {
		sgets(sd, recv_json);
		printf("<<<%s>>>\n", recv_json);
		json_t *root = load_json(recv_json);
		int width = json_integer_value(json_object_get(root, "width"));
		int height = json_integer_value(json_object_get(root, "height"));
		int finished = json_boolean_value(json_object_get(root, "finished"));
		char* turn_team = json_string_value(json_object_get(root, "turn_team"));
		printf("%d, %d, %d", width, height, finished);
		fflush(0);
		if (finished)
			break;

		// 自分の手番の場合
		if (strcmp(turn_team, TEAM_NAME) == 0) {
			printf("my turn");
			// 自分の手番でない場合
			sputs(sd, "{\"a\", \"b\"}\n");
			// 結果の取得
			sgets(sd, recv_json);
			printf("%s\n", recv_json);
		}

	}
	printf("end");
	fflush(0);
	// ソケットを閉じる
	close(sd);

	return 0;
}

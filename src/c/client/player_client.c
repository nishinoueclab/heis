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

/* forward refs */
void print_json(json_t *root);
void print_json_aux(json_t *element, int indent);
void print_json_indent(int indent);
const char *json_plural(int count);
void print_json_object(json_t *element, int indent);
void print_json_array(json_t *element, int indent);
void print_json_string(json_t *element, int indent);
void print_json_integer(json_t *element, int indent);
void print_json_real(json_t *element, int indent);
void print_json_true(json_t *element, int indent);
void print_json_false(json_t *element, int indent);
void print_json_null(json_t *element, int indent);

void print_json(json_t *root) {
	print_json_aux(root, 0);
}

void print_json_aux(json_t *element, int indent) {
	switch (json_typeof(element)) {
	case JSON_OBJECT:
		print_json_object(element, indent);
		break;
	case JSON_ARRAY:
		print_json_array(element, indent);
		break;
	case JSON_STRING:
		print_json_string(element, indent);
		break;
	case JSON_INTEGER:
		print_json_integer(element, indent);
		break;
	case JSON_REAL:
		print_json_real(element, indent);
		break;
	case JSON_TRUE:
		print_json_true(element, indent);
		break;
	case JSON_FALSE:
		print_json_false(element, indent);
		break;
	case JSON_NULL:
		print_json_null(element, indent);
		break;
	default:
		fprintf(stderr, "unrecognized JSON type %d\n", json_typeof(element));
	}
}

void print_json_indent(int indent) {
	int i;
	for (i = 0; i < indent; i++) {
		putchar(' ');
	}
}

const char *json_plural(int count) {
	return count == 1 ? "" : "s";
}

void print_json_object(json_t *element, int indent) {
	size_t size;
	const char *key;
	json_t *value;

	print_json_indent(indent);
	size = json_object_size(element);

	printf("JSON Object of %ld pair%s:\n", size, json_plural(size));
	json_object_foreach(element, key, value)
	{
		print_json_indent(indent + 2);
		printf("JSON Key: \"%s\"\n", key);
		print_json_aux(value, indent + 2);
	}

}

void print_json_array(json_t *element, int indent) {
	size_t i;
	size_t size = json_array_size(element);
	print_json_indent(indent);

	printf("JSON Array of %ld element%s:\n", size, json_plural(size));
	for (i = 0; i < size; i++) {
		print_json_aux(json_array_get(element, i), indent + 2);
	}
}

void print_json_string(json_t *element, int indent) {
	print_json_indent(indent);
	printf("JSON String: \"%s\"\n", json_string_value(element));
}

void print_json_integer(json_t *element, int indent) {
	print_json_indent(indent);
	printf("JSON Integer: \"%" JSON_INTEGER_FORMAT "\"\n",
			json_integer_value(element));
}

void print_json_real(json_t *element, int indent) {
	print_json_indent(indent);
	printf("JSON Real: %f\n", json_real_value(element));
}

void print_json_true(json_t *element, int indent) {
	(void) element;
	print_json_indent(indent);
	printf("JSON True\n");
}

void print_json_false(json_t *element, int indent) {
	(void) element;
	print_json_indent(indent);
	printf("JSON False\n");
}

void print_json_null(json_t *element, int indent) {
	(void) element;
	print_json_indent(indent);
	printf("JSON Null\n");
}

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

#define MAX_CHARS 4096

char* substring(char *d, char *s, int m, int n){
	int N;
	N=strlen(s);
	if((0<=m && m <= N) && (0 < n && n < N) && (m < n)){
		strncpy(d,s+m,n-m);
		d[n-m]='\0';
	}else
		d[0]='\0';
	return d;

}

// バッファから1行取り出す。(get string)
// 改行に当たるまで待機します。


char* gets(int sd, char* line) {
	// 前回改行までに取り出した部分
	static char* read_buf = NULL;
	if(read_buf == NULL) {
		read_buf = malloc(sizeof(char) * RECV_SIZE);
		read_buf[0] = '\0';
	}

	while (1) {
		printf("loop\n");
		int e;
		if(strlen(read_buf)!=(e=strcspn(read_buf, "\n"))){
			substring(line, read_buf, 0, e + 1);
			// 先頭を取り出す
			char* temp = malloc(sizeof(char) * RECV_SIZE);
			strcpy(temp, strchr(read_buf, '\n'));
			free(read_buf);
			read_buf = temp;
			printf("line: <<<%s>>>\n", line);
			printf("read_buf: <<<%s>>>\n", read_buf);
			break;
		}
		char r[99999];
		r[0] = '\0';

		if ((e = recv(sd, r, sizeof(r) * RECV_SIZE, 0)) < 0) {
			perror("recv");
			return NULL;
		}

		strcat(read_buf, r);

		for(int i = 0; i < 50; i++) {
			printf("r[%d] = \"%c \"\n",i, r[i]);
			if(r[i] == '\0')
				break;
		}
		printf("r = <<<%s>>>\n", r);
		printf("read_buf = <<<%s>>>\n", read_buf);
	}

	return line;
}


//
//void puts() {
//
//}

int main(int argc, char *argv[]) {
	int sd;  //ソケット作成用の変数
	struct sockaddr_in addr;  //サーバ接続用の変数
	char *recv_json;  //受信データ格納用の変数
	recv_json = (char *) malloc(sizeof(char) * RECV_SIZE);
//	char *send_json; //送信データ格納用の変数
//	send_json = (char *) malloc(sizeof(send_json) * (SEND_SIZE + 2));

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
//	if (recv(sd, recv_json, RECV_SIZE, 0) < 0) {
//		perror("recv");
//		return -1;
//	}
	gets(sd, recv_json);
	printf("request name: <<<%s>>>\n", recv_json);

	// 名前送信
	char* name_json = malloc(sizeof(name_json) * (SEND_SIZE + 2));
	sprintf(name_json, "{\"team_name\": \"%s\"}\n", TEAM_NAME);
	if (send(sd, name_json, SEND_SIZE + 2, 0) < 0) {
		perror("send");
		return -1;
	}
	free(name_json);

	// 名前確定

//		if (recv(sd, recv_json, sizeof(recv_json) * RECV_SIZE, 0) < 0) {
//			perror("recv");
//			return -1;
//		}
		gets(sd, recv_json);
		printf("defined name: <<<%s>>>\n", recv_json);


	// 盤面情報
	while (1) {
		if (recv(sd, recv_json, sizeof(recv_json) * RECV_SIZE, 0) < 0) {
			perror("recv");
			return -1;
		}
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
			char* action_json = malloc(sizeof(action_json) * (SEND_SIZE + 2));
			sprintf(action_json, "{\"turn_team\": \"%s\", \"contents\":[]}\n",
			TEAM_NAME);
			if (send(sd, action_json, strlen(action_json) + 1, 0) < 0) {
				perror("send");
				return -1;
			}
			// 結果の取得
			if (recv(sd, recv_json, sizeof(recv_json) * RECV_SIZE, 0) < 0) {
				perror("recv");
				return -1;
			}
			printf("%s\n", recv_json);
			free(action_json);
		}

	}
	printf("end");
	fflush(0);
	// ソケットを閉じる
	close(sd);
//	while (read_line(line, MAX_CHARS) != (char *) NULL) {
//
//		/* parse text into JSON structure */
//		json_t *root = load_json(line);
//
//		if (root) {
//			/* print and release the JSON structure */
//			print_json(root);
//			json_decref(root);
//		}
//	}

	return 0;
}

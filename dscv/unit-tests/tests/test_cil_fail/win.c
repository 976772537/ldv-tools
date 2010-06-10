int SAFE() {}
int UNSAFE() {}
int UNKNOWN() {}

cil doesn't process this file! :-(

int main() {
	SAFE();
	return 0;
}


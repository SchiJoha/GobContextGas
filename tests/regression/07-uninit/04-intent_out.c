// PARAM: --set ana.activated "['base','threadid','threadflag','escape','uninit','mallocWrapper']"  --set exp.privatization none
void some_function(int* x){
	*x = 0;
}

int main(){
	int v;
	some_function(&v);
	return v; //NOWARN
}

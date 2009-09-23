provider BMScript {
    probe start_execute(char * scriptSource, int isTemplate);
    probe end_execute(char * result);
};
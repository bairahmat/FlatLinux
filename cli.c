#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

void trim(char *string, int num);

int
main (int argc, char *argv[])
{
	FILE *temp;
	char *partition;
	char *location;
	char *timezone;
	int exit_code;
	char *answer;
	size_t getline_max=(size_t)25;
	char *command;
	
	exit_code=system("tzselect > temp");
	if(exit_code!=0){
		fprintf(stderr, "Tzselect failed.\n");
		return 1;
	}
	temp=fopen("temp", "r");
	if(temp==NULL){
		fprintf(stderr, "Reading timezone failed.\n");
		return 1;
	}
	timezone=(char *)malloc((size_t)25);
	getline_max=(size_t)25;
	exit_code=getline(&timezone, &getline_max, temp);
	if(exit_code==-1){
		fprintf(stderr, "Reading timezone failed.\n");
		return 1;
	}
	fclose(temp);
	exit_code=unlink("temp");
	if(exit_code==-1)
		printf("WARN: Couldn't delete temperary file.");
	trim(timezone, 1);
	printf("Is %s the correct timezone?\n(Y/n): ", timezone);
	getline_max=(size_t)1;
	answer=(char *)malloc(2);
	exit_code=getline(&answer, &getline_max, stdin);
	trim(answer, 1);
	if(!((strncmp(answer, "\n", (size_t)1)==0) || (strncmp(answer, "Y", (size_t)1)==0) || (strncmp(answer, "y", (size_t)1)==0))){
		return 1;
	}
	printf("What partition would you like FlatLinux installed on?\n");
	partition=(char *)malloc(9);
	getline_max=10;
	exit_code=getline(&partition, &getline_max, stdin);
	trim(partition, 1);
	if(exit_code==-1){
		fprintf(stderr, "Error.\n");
		return 1;
	}
	if(access(partition, F_OK)==-1){
		fprintf(stderr, "%s doesn't exist.", partition);
		return 1;
	}
	printf("Where is %s mounted? Press ENTER if %s isn't mounted.\n", partition, partition);
	location=(char *)malloc(20);
	getline_max=20;
	exit_code=getline(&location, &getline_max, stdin);
	trim(location, 1);
	if(exit_code==-1){
		fprintf(stderr, "Error.\n");
		return 1;
	}
	if(strncmp("\n", location, 1)==0){
		printf("Where would you like %s mounted?\n", partition);
		getline_max=20;
		exit_code=getline(&location, &getline_max, stdin);
		trim(location, 1);
		if(exit_code==-1){
			fprintf(stderr, "Error.\n");
			return 1;
		}
		command=(char *)malloc(40);
		strcpy(command, "mount ");
		strcat(command, partition);
		strcat(command, " ");
		strcat(command, location);
		exit_code=system(command);
		if(exit_code!=0){
			fprintf(stderr, "Error mounting %s on %s.\n", partition, location);
			return 1;
		}
		free(command);
	}else{
		command=(char *)malloc(40);
		strcpy(command, "mountpoint -q ");
		strcat(command, location);
		exit_code=system(command);
		if(exit_code!=0){
			fprintf(stderr, "%s is not a mountpoint.", location);
			return 1;
		}
		free(command);
	}
	/*have location, partition, and timezone.*/
	return 0;
}

/*Takes the last num characters off of string*/
void
trim(char *string, int num)
{
	int i=0;
	while(string[i]!=0)
		i++;
	string[i-num]=0;
}

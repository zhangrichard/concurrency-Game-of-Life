// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
#include "i2c.h"
//#include "gameLogic.h"
#define  IMHT 16                  //image height
#define  IMWD 16                  //image width
#define  LIVE 255
typedef unsigned char uchar;      //using uchar as shorthand
#define  HALF  IMHT/2
on tile[0]:port p_scl = XS1_PORT_1E;         //interface ports to accelerometer
on tile[0]:port p_sda = XS1_PORT_1F;
#define DEBUG 0
#define FXOS8700EQ_I2C_ADDR 0x1E  //register addresses for accelerometer
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6
#define numberOfWorker 4
char infname[] = "test.pgm";
char outfname[] = "testout.pgm";
on tile[0] : in port buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0] : out port leds = XS1_PORT_4F;   //port to access xCore-200 LEDs

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from PGM file from path infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////


int showLEDs(out port p, chanend fromVisualiser) {
  int pattern; //1st bit...separate green LED
               //2nd bit...blue LED
               //3rd bit...green LED
               //4th bit...red LED for reading
  while (1) {
    fromVisualiser :> pattern;   //receive new pattern from visualiser
    p <: pattern;                //send pattern to LED port

  }
  return 0;
}
//int checkrules(uchar farm[IMHT][IMWD], int n, int m) {
//
//    // 4 rules
//    int neighbourlive = 0;
//
//    //check neibourlive number
//    for (int i = n - 1; i <= n + 1; i++) {
//        for (int j = m - 1; j <= m + 1; j++) {
//            if (i >= 0 && j >= 0 && i < 16 && j < 16) {
//                //check not outbound
//                if (farm[i][j] == LIVE &&!(i==n && j==m )) {
//                    neighbourlive++;
//
//                }
//            }
//        }
//    }
//    if (farm[n][m] == LIVE) {
//        if (neighbourlive < 2) return 0;
//        if (neighbourlive == 2 || neighbourlive == 3) return farm[n][m];
//        if (neighbourlive > 3) return 0;
//    }
//    else if (neighbourlive == 3) return LIVE;
//    else return farm[n][m];
//
//}
void visualiser(chanend distributorToVisualiser, chanend toLEDs) {
//  unsigned int userAntToDisplay = 11;
//  unsigned int attackerAntToDisplay = 2;
//  int pattern = 0;
//  int round = 0;
//  int distance = 0;
//  int dangerzone = 0;
//  while (1) {
//    if (round==0) printstr("ANT DEFENDER GAME (press button to start)\n");
//    round++;
//    select {
//      case fromUserAnt :> userAntToDisplay:
//         //stop signal
//          if (userAntToDisplay==-1){
//              toLEDs <: -1;
//              return;
//          }
//        consolePrint(userAntToDisplay,attackerAntToDisplay);
//        break;
//      case fromAttackerAnt :> attackerAntToDisplay:
//        consolePrint(userAntToDisplay,attackerAntToDisplay);
//        break;
//    }
//    distance = userAntToDisplay-attackerAntToDisplay;
//    dangerzone = ((attackerAntToDisplay==7) || (attackerAntToDisplay==15));
//    pattern = round%2 + 8 * dangerzone + 2 * ((distance==1) || (distance==-1));
//    if ((attackerAntToDisplay>7)&&(attackerAntToDisplay<15)) pattern = 15;
    int pattern;
    distributorToVisualiser:>pattern;
    printf("led value is %d",pattern);
    toLEDs <: pattern;
//  }
}
//WAIT function
void waitMoment() {
  timer tmr;
  int waitTime;
  tmr :> waitTime;                       //read current timer value
  waitTime += 40000000;                  //set waitTime to 0.4s after value
  tmr when timerafter(waitTime) :> void; //wait until waitTime is reached
}

void DataInStream( char infname[],chanend c_out)
{

  int res;
  uchar line[ IMWD ];
  printf( "DataInStream: Start...\n" );

  //Open PGM file
  res = _openinpgm( infname, IMWD, IMHT );
  if( res ) {
    printf( "DataInStream: Error openening %s\n.", infname );
    return;
  }

  //Read image line-by-line and send byte by byte to channel c_out
  for( int y = 0; y < IMHT; y++ ) {
    _readinline( line, IMWD );
    // pass first half
    for( int x = 0; x < IMWD; x++ ) {
      c_out <: line[ x ];
      printf( "-%4.1d ", line[ x ] ); //show image values
    }

    printf( "\n" );
  }

  //Close PGM image file
  _closeinpgm();
  printf( "DataInStream:Done...\n" );
  return;
}

void buttonListener(in port b, chanend toDistributor ) {
  int r;
  int stop;
  while (1) {
      printf("Button start\n");
    b when pinseq(15)  :> r;    // check that no button is pressed
    b when pinsneq(15) :> r;    // check if some buttons are pressed
    if ((r==13) || (r==14))     // if either button is pressed
        toDistributor <: r;             // send button pattern to userAnt
        printf("value of button = %d",r);
  }
}
/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
//
/////////////////////////////////////////////////////////////////////////////////////////


void output(chanend c_out,chanend fromProcess1,chanend fromProcess2){
    if (DEBUG){
        printf("start outputing in output\n");
    }
    int ready1;
    int ready2;
    uchar val;
    select {
        case fromProcess1:>ready1:
    for( int y = 0; y < IMHT/2; y++ ) {   //go through all lines
               for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line

                 fromProcess1 :> val;                    //read the pixel value
                 c_out<:val;
        //         c_out <: (uchar)( val ^ 0xFF ); //send some modified pixel out
               }

             }
    if (DEBUG){
           printf("finish output for process1\n");
       }
    break;
        case fromProcess2:>ready2:
    for( int y = 0; y < IMHT/2; y++ ) {   //go through all lines
                  for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                    fromProcess2 :> val;                    //read the pixel value
                    c_out<:val;
           //         c_out <: (uchar)( val ^ 0xFF ); //send some modified pixel out
                  }
                }
    if (DEBUG){
             printf("finish output for process2\n");
         }
    break;
    }
}

uchar calculateNextValue(uchar farm[IMHT/numberOfWorker+2][IMWD], int n, int m) {
    if (DEBUG){
        printf("calculateing\n");
    }
    //
//    // 4 rules
    int neighbourlive = 0;

    //check neibourlive number
    for (int i = n - 1; i <= n + 1; i++) {
        for (int j = m - 1; j <= m + 1; j++) {
                if (farm[(i+IMHT/numberOfWorker+2)%(IMHT/numberOfWorker+2)][(j+IMWD)%IMWD] == LIVE &&!(i==n && j==m )) {
                    neighbourlive++;
                }
        }
    }

    // the rule here
    if (farm[n][m] == LIVE) {
        if (neighbourlive < 2) return 0;
        if (neighbourlive == 2 || neighbourlive == 3) return farm[n][m];
        if (neighbourlive > 3) return 0;
    }
    else if (neighbourlive == 3) return LIVE;
    else return farm[n][m];

}
void worker(uchar array[IMHT/numberOfWorker+2][IMWD],uchar newArray[IMHT/numberOfWorker][IMWD]){
//    uchar newArray[HALF/4][IMWD];
    if (DEBUG){
        printf("intoWorker\n");
    }
    // only check the half height is enough the addition info is for outbound checking
    for (int y = 0; y < HALF/4; ++y) {
        for (int x = 0; x < IMWD; ++x) {
            newArray[y][x]=calculateNextValue(array,y,x);
        }
    }
//    memcpy(array,newArray,(HALF/4)*IMWD*sizeof(uchar));
}

transaction inArray (chanend c, int data[],int size){
    for (int i = 0;  i < size; ++ i) {
        c<:data[i];
    }
}

//void Process2(chanend fromDistributor){
//    if (DEBUG){
//        printf("intoProcess2\n");
//    }
//    int round =0;
//     int output;
//     int LASTLINE = HALF/4+1;
//     uchar worker1[HALF/4+2][IMWD];// first from bottom, second from top
//     uchar worker2[HALF/4+2][IMWD];
//     uchar worker3[HALF/4+2][IMWD];
//     uchar worker4[HALF/4+2][IMWD];
//     for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//          for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                fromDistributor :> worker1[y][x];                    //read the pixel value
//               }
//         }
//     for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//             for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                   fromDistributor :> worker2[y][x];                    //read the pixel value
//                  }
//            }
//     for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//             for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                   fromDistributor :> worker3[y][x];                    //read the pixel value
//                  }
//            }
//     for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//             for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                   fromDistributor :> worker4[y][x];                    //read the pixel value
//                  }
//            }
//     if (DEBUG){
//             printf("finish initializetion for process2\n");
//         }
//
////     while(1){
//     // process current board
//     // pass to process1
//     //receive from process1
////     printf("erroring message is ");
//     for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//         fromDistributor:>worker1[HALF/4+1][x];
////                    printf("%d",worker1[HALF/4+1][x]);
//                   }
////     printf("\n");
//     for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//         fromDistributor:>worker4[LASTLINE][x];
//          }
//     // into processing
//     par{
//         //get bot
//         memcpy(worker1[HALF/4],worker2[0],IMWD*sizeof(uchar));
//         memcpy(worker2[HALF/4],worker3[0],IMWD*sizeof(uchar));
//         memcpy(worker3[HALF/4],worker4[0],IMWD*sizeof(uchar));
//         //get top
//         memcpy(worker2[LASTLINE],worker1[HALF/4-1],IMWD*sizeof(uchar));
//         memcpy(worker3[LASTLINE],worker2[HALF/4-1],IMWD*sizeof(uchar));
//         memcpy(worker4[LASTLINE],worker3[HALF/4-1],IMWD*sizeof(uchar));
//     }
//     if (DEBUG){
//         printf("finishing allocating2\n");
//     }
//     // start processing
//     printf("start processing \n");
//     par {
//     worker(worker1);
//     worker(worker2);
//     worker(worker3);
//     worker(worker4);
//     }
//     printf("finishing processing \n");
//     if (DEBUG){
//         printf("start outputing2\n");
//     }
////     select{
////         case fromDistributor:>output:
////         if(output){
//                  fromDistributor<:1;
//          for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//                   for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                       fromDistributor <: worker1[y][x];                    //read the pixel value
//                   }
//                  }
//          for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//                   for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                       fromDistributor <: worker2[y][x];                    //read the pixel value
//                        }
//                  }
//          for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//                   for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                       fromDistributor <: worker3[y][x];                    //read the pixel value
//                        }
//                  }
//          for( int y = 0; y < HALF/4; y++ ) {   //go through all lines
//                   for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                       fromDistributor <: worker4[y][x];                    //read the pixel value
//                        }
//                  }
////              }
////         break;
////         default :
////             continue;
////     }
////     round++;
////     }
//
//}
uchar calculateNextValue2(uchar farm[IMHT][IMWD], int n, int m) {
    if (DEBUG){
        printf("calculateing\n");
    }
    //
//    // 4 rules
    int neighbourlive = 0;

    //check neibourlive number
    for (int i = n - 1; i <= n + 1; i++) {
        for (int j = m - 1; j <= m + 1; j++) {
                if (farm[(i+IMHT)%IMHT][(j+IMWD)%IMWD] == LIVE &&!(i==n && j==m )) {
                    neighbourlive++;
                }
        }
    }

    // the rule here
    if (farm[n][m] == LIVE) {
        if (neighbourlive < 2) return 0;
        if (neighbourlive == 2 || neighbourlive == 3) return farm[n][m];
        if (neighbourlive > 3) return 0;
    }
    else if (neighbourlive == 3) return LIVE;
    else return farm[n][m];

}


typedef interface i {
    void f(uchar board[IMHT/numberOfWorker+2][IMWD],int id);
    [[guarded]]void g();
}i;
void myWorker(server interface i myworker,int name){
    uchar  array[IMHT/numberOfWorker+2][IMWD];
    while(1){
        select{
            case myworker.f(uchar board[IMHT/numberOfWorker+2][IMWD],int id):
            memcpy(array,board,(IMHT/numberOfWorker+2)*IMWD*sizeof(uchar));
                    for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
                              for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                                  board[y][x] = calculateNextValue(array,y,x);                    //read the pixel value
                                   }
                         }
            break;
               }
        }
}

void distributor(chanend c_in, chanend c_out, chanend fromAcc,chanend fromButton,client interface i myWorkerI[numberOfWorker])
{
    if (DEBUG){
            printf("intoDistributor\n");
        }
    timer t;
    int start_time;
    int end_time;

    uchar val;
        int round =0;
         int output;
//         static int numberOfWorker = 2;
//         int LASTLINE = HALF/4+1;
         int TOPLINE = 0;
         int LASTLINE = IMHT/numberOfWorker-1;
         uchar board [numberOfWorker][IMHT/numberOfWorker+2][IMWD];
//         uchar nextBoard [numberOfWorker][IMHT/numberOfWorker][IMWD];
         printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );
         printf( "Waiting for Board Tilt...\n" );
           fromAcc :> int value;
         for (int i = 0;i<numberOfWorker;i++){
             for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
                   for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                       c_in :> board[i][y][x];                    //read the pixel value
                        }
              }
         }
//         fromAcc:>int acc;
         t:>start_time;
         while(1){
            fromButton:>int value;
            // get top line
            for(int i = 0;i<numberOfWorker;i++){
                for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                      board[i][IMHT/numberOfWorker+1][x] = board[(i-1+numberOfWorker)%numberOfWorker][LASTLINE][x];                    //read the pixel value
                    }
            }
            //get bot line
            for(int i = 0;i<numberOfWorker;i++){
                for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                      board[i][IMHT/numberOfWorker][x] = board[(i+1+numberOfWorker)%numberOfWorker][0][x];                    //read the pixel value
                    }
            }

            myWorkerI[0].f(board[0],0);
            myWorkerI[1].f(board[1],1);
            myWorkerI[2].f(board[2],2);
            myWorkerI[3].f(board[3],3);
//
//           par(int i = 0;i<numberOfWorker;i++){
//               worker(board[i],nextBoard[i]);
//           }
//             workerInDistributor(board,nextBoard,0);
//             workerInDistributor(board,nextBoard,1);
//         }

         printf("into processing \n");
         for (int i = 0;i<numberOfWorker;i++){
         for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
            for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
//                  c_out <: nextBoard[y][x];
                  printf( "-%4.1d ", board[i][y][x]);//read the pixel value
                 }
            printf("\n");
         }
         }
             printf("round number is %d\n",round);
             round++;
//             memcpy(board,nextBoard,IMHT*IMWD*sizeof(uchar));
             t :> end_time;
             printf("Number of timer ticks elapsed: %u", end_time - start_time);
         }

         //receive from process2

}
/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream( char outfname[],chanend c_in)
{

  int res;
  uchar line[ IMWD ];

  //Open PGM file
  printf( "DataOutStream:Start...\n" );
  res = _openoutpgm( outfname, IMWD, IMHT );
  if( res ) {
    printf( "DataOutStream:Error opening %s\n.", outfname );
    return;
  }

  //Compile each line of the image and write the image line-by-line
  for( int y = 0; y < IMHT; y++ ) {
    for( int x = 0; x < IMWD; x++ ) {
      c_in :> line[ x ];
    }
    _writeoutline( line, IMWD );
  }

  //Close the PGM image
  _closeoutpgm();
  printf( "DataOutStream:Done...\n" );
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Initialise and  read accelerometer, send first tilt event to channel
//
/////////////////////////////////////////////////////////////////////////////////////////
void accelerometer(client interface i2c_master_if i2c, chanend toDist) {
  i2c_regop_res_t result;
  char status_data = 0;
  int tilted = 0;

  // Configure FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }
  
  // Enable FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  //Probe the accelerometer x-axis forever
  while (1) {

    //check until new accelerometer data is available
    do {
      status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    } while (!status_data & 0x08);

    //get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

    //send signal to distributor after first tilt
    if (!tilted) {
      if (x>30) {
        tilted = 1 - tilted;
        toDist <: 1;
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
int main(void) {

//         visualiserToLEDs;       //channel from Visualiser to showLEDs

  i2c_master_if i2c[1];               //interface to accelerometer

  interface  i myWorkerI[numberOfWorker];
//  interface i
     //put your input image path here
 //put your output image path here

  chan c_inIO, c_outIO, c_control,buttonsToDistributor,
  distributorToVisualiser,
  visualiserToLEDs,toDistibutor2,toProcess1,toProcess2,bwProcess;    //extend your channel definitions here

  par {
    on tile[0]:i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing accelerometer data
    on tile[0]:accelerometer(i2c[0],c_control);        //client thread reading accelerometer data
    on tile[0]:DataInStream(infname, c_inIO);          //thread to read in a PGM image
    on tile[0]:DataOutStream(outfname, c_outIO);       //thread to write out a PGM image
    on tile[0]:distributor(c_inIO, c_outIO, c_control,buttonsToDistributor,myWorkerI);//thread to coordinate work on image
    //HELPER PROCESSES USING BASIC I/O ON X-CORE200 EXPLORER
//    on tile[0]:Process1(toProcess1,bwProcess);
//    on tile[1]:Process2(toProcess2);
//    on tile[0]: distributor2(toDistibutor2);
    on tile[1]:myWorker(myWorkerI[0],0);
    on tile[1]:myWorker(myWorkerI[1],1);
    on tile[0]:myWorker(myWorkerI[2],1);
    on tile[0]:myWorker(myWorkerI[3],1);

    on tile[0]: buttonListener(buttons, buttonsToDistributor);
//    on tile[0]: visualiser(distributorToVisualiser,visualiserToLEDs);
//    on tile[0]: showLEDs(leds,visualiserToLEDs);
  }

  return 0;
}

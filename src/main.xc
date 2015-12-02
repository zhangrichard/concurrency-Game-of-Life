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
#define numberOfWorker 8
char infname[] = "test.pgm";
char outfname[] = "testout.pgm";
on tile[0] : in port buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0] : out port leds = XS1_PORT_4F;   //port to access xCore-200 LEDs

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from PGM file from path infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////

int showLEDs(out port p, chanend fromDist) {
  int pattern; //1st bit...separate green LED
               //2nd bit...blue LED
               //3rd bit...green LED
               //4th bit...red LED for reading
  while (1) {
    fromDist :> pattern;   //receive new pattern from visualiser
    p <: pattern;                //send pattern to LED port
  }
  return 0;
}
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
uchar calculateNextValue(uchar farm[IMHT/numberOfWorker+2][IMWD], int n, int m) {
//    if (n ==1 && m ==1){
//        printf("calculateing\n");
//    }
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

void distributor(chanend c_in, chanend c_out, chanend fromAcc,chanend fromButton,client interface i myWorkerI[numberOfWorker],chanend ToLEDs)
{
    if (DEBUG){
            printf("intoDistributor\n");
        }
    timer t;
    int SEPGREEN = 1;
    int GREEN = 1<<2;
    int BLUE =1<<1;
    int RED = 1<<3;
    int start_time;
    int end_time;
    int numberOfLiveCells;
    int val;
    int tilt;
        int round =0;
         int output;
//         static int numberOfWorker = 2;
//         int LASTLINE = HALF/4+1;
         int Horizontal = 0;
         int TOPLINE = 0;
         int LASTLINE = IMHT/numberOfWorker-1;
         uchar board [numberOfWorker][IMHT/numberOfWorker+2][IMWD];
//         uchar nextBoard [numberOfWorker][IMHT/numberOfWorker][IMWD];
         printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );
         printf( "Waiting for Board Tilt...\n" );
//           fromAcc :> int value;
//           fromButton:> val;
           while(val!=14){   ///right start game
               fromButton:> val;
           }
           ToLEDs <: GREEN;
           printf("reading from file \n");
         for (int i = 0;i<numberOfWorker;i++){
             for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
                   for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                       c_in :> board[i][y][x];                    //read the pixel value
                        }
              }
         }
//         fromAcc:>int acc;
         t:>start_time;
         printf("start timing \n");
         while(1){
             fromAcc :> tilt;
             // pause  game
            if (tilt != Horizontal){
                ToLEDs<:RED;
                for (int i = 0;i<numberOfWorker;i++){
                    for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
                       for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                           if (board[i][y][x] == 255){
                               numberOfLiveCells++;
                           }
                             printf( "-%4.1d ", board[i][y][x]);//read the pixel value
                            }
                       printf("\n");
                    }
                }
                printf("Number of cell lives %d\n",numberOfLiveCells);
                printf("round number is %d\n",round);
                t :> end_time;
                printf("Number of seconds: %u s", (end_time - start_time)/10000000);
            } else
          // continue game
            {
             select {
                 case fromButton:> val:
                     if (val == 13){
                         //out put data
                         printf("outputing data\n");
                         ToLEDs<:BLUE;
                         for (int i = 0;i<numberOfWorker;i++){
                             for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
                                for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                                      c_out<: board[i][y][x];//read the pixel value
                                     }
                             }
                         }
                     }
                     break;
              default:
                  ToLEDs<:SEPGREEN;
                  printf("into processing \n");
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
                         // sending and receiving from worker
                         for (int id = 0; id<numberOfWorker;id++){
                             myWorkerI[id].f(board[id],id);
                         }
                         printf("finishing round %d\n",round);
                         printf("round number is %d\n",round);
                         round++;
                         break;
                 }
               }
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
//    if (!tilted) {
      if (x>30) {
//        tilted = 1 - tilted;
        toDist <: 1;
      }else
      {
          toDist<:0;
      }
//    }
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
  distributorToVisualiser,distributorToLEDs,
  visualiserToLEDs,toDistibutor2,toProcess1,toProcess2,bwProcess;    //extend your channel definitions here

  par {
    on tile[0]:i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing accelerometer data
    on tile[0]:accelerometer(i2c[0],c_control);        //client thread reading accelerometer data
    on tile[0]:DataInStream(infname, c_inIO);          //thread to read in a PGM image
    on tile[1]:DataOutStream(outfname, c_outIO);       //thread to write out a PGM image
    on tile[1]:distributor(c_inIO, c_outIO, c_control,buttonsToDistributor,myWorkerI,distributorToLEDs);//thread to coordinate work on image
    //HELPER PROCESSES USING BASIC I/O ON X-CORE200 EXPLORER
//    on tile[0]:Process1(toProcess1,bwProcess);
//    on tile[1]:Process2(toProcess2);
//    on tile[0]: distributor2(toDistibutor2);
    on tile[1]:myWorker(myWorkerI[0],0);
    on tile[1]:myWorker(myWorkerI[1],1);
    on tile[0]:myWorker(myWorkerI[2],2);
    on tile[0]:myWorker(myWorkerI[3],3);

    on tile[1]:myWorker(myWorkerI[4],4);
    on tile[1]:myWorker(myWorkerI[5],5);
    on tile[0]:myWorker(myWorkerI[6],6);
    on tile[0]:myWorker(myWorkerI[7],7);
    on tile[0]: buttonListener(buttons, buttonsToDistributor);
//    on tile[0]: visualiser(distributorToVisualiser,visualiserToLEDs);
    on tile[0]: showLEDs(leds,distributorToLEDs);
  }

  return 0;
}

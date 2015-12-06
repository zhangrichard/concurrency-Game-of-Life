// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
#include "i2c.h"
//#include "gameLogic.h"
#define  INIMHT 512                  // input image height
#define INIMWD 512                   // input image height
#define  IMHT INIMHT                  //image height
#define  IMWD (INIMWD/8)                  // image width
#define  LIVE 1
#define numberOfWorker 4
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

char infname[] = "512x512.pgm";
char outfname[] = "512x512_out.pgm";
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

void DataInStream( char infname[],chanend c_out)
{

  int res;
  uchar line[ INIMWD ];
  printf( "DataInStream: Start...\n" );

  //Open PGM file
  res = _openinpgm( infname, INIMWD, IMHT );
  if( res ) {
    printf( "DataInStream: Error openening %s\n.", infname );
    return;
  }
  //Read image line-by-line and send byte by byte to channel c_out
  for( int y = 0; y < IMHT; y++ ) {
    _readinline( line, INIMWD );
    // pass first half
    for( int x = 0; x < INIMWD; x++ ) {
      c_out <: line[ x ];
//      printf( "-%4.1d ", line[ x ] ); //show image values
    }

//    printf( "\n" );
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
//uchar bitValue(uchar input ,int position){
//    uchar result;
//    return result |= (input[i] == '1') << (7 - position);
//}
uchar calculateNextValue(uchar farm[IMHT/numberOfWorker+2][IMWD], int n, int m,int index) {

//    // 4 rules
    int neighbourlive = 0;
    uchar CurrentCell = farm[(n+IMHT/numberOfWorker+2)%(IMHT/numberOfWorker+2)][(m+IMWD)%IMWD] >> (7-index)&1;
    //check neibourlive number
    for (int i = n - 1; i <= n + 1; i++) {
        for (int j = index - 1; j <= index + 1; j++) {
            uchar Cell = 0;
            int row = (i+IMHT/numberOfWorker+2)%(IMHT/numberOfWorker+2);
            if(j==-1){
             Cell= farm[row][(m-1+IMWD)%IMWD] >> 0 &1;
            }
            else if (j==8){
              Cell = farm[row][(m+1+IMWD)%IMWD] >> 7&1;
            }else{
                Cell = farm[row][(m+IMWD)%IMWD] >> (7-j)&1;
            }
            if (Cell== LIVE&&!(i==n&&j==index)) {
                    neighbourlive++;
                }
        }
    }
    // the rule here
    if (CurrentCell == LIVE) {
        if (neighbourlive < 2) return 0;
        if (neighbourlive == 2 || neighbourlive == 3) return 1;
        if (neighbourlive > 3) return 0;
    }
    else if (neighbourlive == 3) return 1;
    else return 0;

}
typedef interface i {
    void send(uchar board[IMHT/numberOfWorker+2][IMWD],int id);
    void receive(uchar board[IMHT/numberOfWorker+2][IMWD]);
}i;
void myWorker(server interface i myworker,int name){
    uchar  array[IMHT/numberOfWorker+2][IMWD];
    uchar  output[IMHT/numberOfWorker+2][IMWD];
    int receive = 0;
    while(1){
        select{
            case myworker.send(uchar board[IMHT/numberOfWorker+2][IMWD],int id):
            memcpy(array,board,(IMHT/numberOfWorker+2)*IMWD*sizeof(uchar));
            receive = 0;
            break;

        case myworker.receive(uchar board[IMHT/numberOfWorker+2][IMWD]):
            for (int y = 0; y<IMHT/numberOfWorker;y++){
                for (int x = 0;x<IMWD;x++){
                    board[y][x] = output[y][x];
                }
            }
            receive = 1;
        break;
            }
        if (receive){
            continue;
        }
        // calculate
        for (int y = 0; y<IMHT/numberOfWorker;y++){
            for (int x = 0;x<IMWD;x++){
                uchar result=0;
                for (int i = 0; i < 8; i++){
                    result |= calculateNextValue(array,y,x,i)<<(7-i);
                }
                output[y][x] = result;
            }
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
    unsigned int start_time;
    unsigned int end_time;
    unsigned int period = 20*100000000;
    unsigned int timeLast = 0;
    int val =0;
    uchar inputVal;
    int tilt;
        int round =0;
         int output;
         int Horizontal = 0;
         int TOPLINE = 0;
         int LASTLINE = IMHT/numberOfWorker-1;
         uchar board [numberOfWorker][IMHT/numberOfWorker+2][IMWD];
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
                       uchar result = 0;
                       for (int j = 0;j<8;j++){
                           c_in :> inputVal;
                           result |= (inputVal==255) <<(7-j);
                       }
                       board[i][y][x] = result;                    //read the pixel value

                   }
              }
         }
//         fromAcc:>int acc;
         t:>start_time;
         printf("start timing \n");
         while(1){
             fromAcc :> tilt;
             // pause  game
             if (round ==100){
                 t :> end_time;
                timeLast += (end_time - start_time)/100000000;
                t:>start_time;
                printf("Number of seconds: %u s", timeLast);
             }

            if (tilt != Horizontal){
                ToLEDs<:RED;
                int numberOfLiveCells = 0;
                t :> end_time;
               timeLast += (end_time - start_time)/100000000;
               t:>start_time;
                for (int i = 0;i<numberOfWorker;i++){
                    for( int y = 0; y < IMHT/numberOfWorker; y++ ) {   //go through all lines
                       for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                           uchar result =board[i][y][x];
                               for (int i = 0;i<8;i++){
                                   uchar temp = result >>(7-i) &1;
                                   if (temp == LIVE){
                                       numberOfLiveCells++;
                                   }
                                   printf( "-%4.1d ",temp*255);
                               }
                            }
                       printf("\n");
                    }
                }


                printf("Number of seconds: %u s", timeLast);
                printf("Number of cell lives %d\n",numberOfLiveCells);
                printf("round number is %d\n",round);

                while(tilt != Horizontal)
                    {
                    select {
                        case fromAcc:> tilt:

                        break;
                    case t when timerafter(start_time + period) :> void:
//                       // restart timer
                         t:>start_time;
                        timeLast += 20;
                        break;
                    }
                    }
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
                                    uchar result = board[i][y][x];
                                       for (int i = 0;i<8;i++){
                                           uchar val =  (result >>(7-i) &1)*255;
                                           c_out<: val;
                                       }
                                     }
                             }
                         }
                     }
                     break;
                 case t when timerafter(start_time + period) :> void:
//                       // restart timer
                         t:>start_time;
                        timeLast += 20;
                        continue;
              default:
                  if(round%2){
                      ToLEDs<:SEPGREEN;
                  }
//                  printf("into processing \n");
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
                             myWorkerI[id].send(board[id],id);
                         }
                         for (int id = 0; id<numberOfWorker;id++){
                              myWorkerI[id].receive(board[id]);
                          }
                         printf("finishing round %d\n",round);
                         round++;
                         break;
                 }
                 ToLEDs<:0;
               }

             }

}
/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream( char outfname[],chanend c_in)
{
  while(1){
  int res;
  uchar line[ INIMWD ];

  //Open PGM file
  printf( "DataOutStream:Start...\n" );
  res = _openoutpgm( outfname, INIMWD, IMHT );
  if( res ) {
    printf( "DataOutStream:Error opening %s\n.", outfname );
    return;
  }

  //Compile each line of the image and write the image line-by-line
  for( int y = 0; y < IMHT; y++ ) {
    for( int x = 0; x < INIMWD; x++ ) {
      c_in :> line[ x ];
    }
    _writeoutline( line, INIMWD );
  }

  //Close the PGM image
  _closeoutpgm();
  printf( "DataOutStream:Done...\n" );
  }
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
        toDist <: 1;
      }else
      {
          toDist<:0;
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
  distributorToVisualiser,distributorToLEDs,
  visualiserToLEDs,toDistibutor2,toProcess1,toProcess2,bwProcess;    //extend your channel definitions here

  par {
    on tile[0]:i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing accelerometer data
    on tile[0]:accelerometer(i2c[0],c_control);        //client thread reading accelerometer data
    on tile[0]:DataInStream(infname, c_inIO);          //thread to read in a PGM image
    on tile[1]:DataOutStream(outfname, c_outIO);       //thread to write out a PGM image
    on tile[1]:distributor(c_inIO, c_outIO, c_control,buttonsToDistributor,myWorkerI,distributorToLEDs);//thread to coordinate work on image
    //HELPER PROCESSES USING BASIC I/O ON X-CORE200 EXPLORER
    on tile[1]:myWorker(myWorkerI[0],0);
    on tile[1]:myWorker(myWorkerI[1],1);
    on tile[0]:myWorker(myWorkerI[2],2);
    on tile[0]:myWorker(myWorkerI[3],3);

//    on tile[0]:myWorker(myWorkerI[4],4);
//    on tile[0]:myWorker(myWorkerI[5],5);
//    on tile[0]:myWorker(myWorkerI[6],6);
//    on tile[0]:myWorker(myWorkerI[7],7);
    on tile[0]: buttonListener(buttons, buttonsToDistributor);
    on tile[0]: showLEDs(leds,distributorToLEDs);
  }

  return 0;
}

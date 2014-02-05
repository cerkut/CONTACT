///////////////////////////
// Contact Audio Surface //
// Felix Faire 2013      //
///////////////////////////

import toxi.physics2d.*;
import toxi.physics2d.behaviors.*;
import toxi.geom.*;
import processing.opengl.*;
import javax.media.opengl.*;

import processing.serial.*;
import cc.arduino.*;

import com.onformative.leap.LeapMotionP5;

// OSC Variables
// start OSC config
import oscP5.*;
import netP5.*;
//Setup Osc ports
int portToListenTo = 7401; 
int portToSendTo = 7400;
String ipAddressToSendTo = "127.0.0.1";
OscP5 oscP5;
NetAddress myRemoteLocation;
float message = 0;
float messageHold = 0;
float messageStatic = 0;

boolean flip = false;

// key note variables
int currentKey = 0;
int octaveShift = 4;
int transpose = 12;
boolean aeolian = true;
String[] keys = new String[12];
String[] aeolianKey = new String[7];
int[] aeolianNum = new int[7];
PFont font;

// effect variables
float reverb;
float hiPass;
float lowPass;

// variables for chains
Chain chainTemp;
ArrayList<Chain> chains;
ArrayList<ChainBreak> snaps;
Vec2D jolt;
VerletPhysics2D physics;

//variables for chain movement
boolean displaced = false;
boolean snapped = false;
float tK = 0;
float tS = 0;
int xPos = 25;

// variables for field
Field field;
PVector mouse;
boolean warp = false;
float maxLeft = 0.5;
float maxRight = 1;

// variables for shaders
PShader blur;
boolean blurred = false;
float rev = 0;

// variables for leap
LeapMotionP5 leap;
float fingY;
float scaleFactor = 0.5f;
PVector fingerPos;

// variables for arduino pedal
Arduino a;
float tP = 0;
int pedalClick = 0;

/////////////////////////////////////////////////////////////////////////////

void setup() {
  size(1280, 800, OPENGL);
  physics = new VerletPhysics2D();
  physics.setWorldBounds(new Rect(0, 0, width, height));

  chains = new ArrayList<Chain>();
  snaps = new ArrayList<ChainBreak>();

  // Initialize the chain
  for (int i = 0; i < 5; i++) {
    chainTemp = new Chain(width, 50, 1);
    chains.add(chainTemp);
    snaps.add(new ChainBreak(chainTemp));
  }

  // leap setup
  leap = new LeapMotionP5(this);
  fingerPos = new PVector(0, 0, 0);

  // arduino setup
  a = new Arduino(this, Arduino.list()[0], 57600);

  // field setup
  field = new Field(100);
  mouse = new PVector(0, 0);

  rectMode(CORNERS);
  colorMode(HSB);
  textAlign(CENTER, CENTER);

  blur = loadShader("blurStrong.glsl");

  initialiseKeys();
  font = createFont("Aovel Sans Light", 300);

  // osc setup
  oscP5 = new OscP5(this, portToListenTo);
  myRemoteLocation = new NetAddress(ipAddressToSendTo, portToSendTo);
}

void draw() {
  if (flip) {
    translate(width, height);
    rotate(PI);
  }
  filter(blur);  
  fill(0, 255 - rev);
  noStroke();
  rect(0, 0, width, height);

  drawField();

  rev = 110 + 31*reverb;  //110 - 141

  pedalControl();

  physics.update();

  drawChains();

  drawSnaps();

  //drawDistance();

  fingerControl();

  drawAllFingers();
}

////////////////////////////////////////////////////////////////////////////////

// drawing functions //////////////////////////////////////////////

void drawChains() {
  for (int i = 0; i < 5; i++) {
    chains.get(i).display();
  }

  if (displaced) tK += 8/rev;
  for (int j = 0; j < 5; j++) {
    for (int i = 0; i < chains.get(1).springs.size(); i ++) {
      chains.get(j).springs.get(i).setStrength(constrain(tK*(j+1)/5, 0, 2));
    }
  }
}

void drawSnaps() {
  if (snapped) {
    stroke(255, 255-255*tS);

    for (int i = 0; i < snaps.size(); i++) {
      snaps.get(i).update();
      snaps.get(i).display();
    }

    tS += 0.02 ;

    if (tS > 1) {
      tS = 0;
      snapped = false;
    }
  }
}

void drawField() {

  if (warp) {
    field.update(mouse);
    if (field.timer < 0) warp = false;
  }
  field.display();
}

void displaceField(float xp) {
  mouse.set(xp, height*0.5 + random(100)-50);
  warp = true;
  field.timer = 3*PI;
}

void kick() {
  jolt = new Vec2D(0, random(800)-400);

  for (int i = 0; i < 5; i++) {
    chains.get(i).particles.get(xPos).addSelf(jolt);
  }

  tK = 0;

  displaced = true;
}

//void drawDistance() {
//  messageHold = map(message, maxLeft, maxRight, 0, width);
//  line(messageHold, 0, messageHold, height);
//}

// Keyboard control functions //////////////////////////////////////////////

void keyPressed() {
  if (key == 'v') {
    maxLeft = message;
  }
  if (key == 'b') {
    maxRight = message;
  }
  if (key == 'a') {
    aeolian = !aeolian;
  }
  if (key == '-') {
    transpose -= 1;
    transposeKeys();
  }
  if (key == '=') {
    transpose += 1;
    transposeKeys();
  }
  if (key == 'f'){
    flip = !flip;
  }
}

// Arduino control functions //////////////////////////////////////////////

void pedalControl() {
  if (a.analogRead(0) > 0 && pedalClick == 0) {
    pedalClick = 1;
    OscMessage myMessage = new OscMessage("/loop");
    myMessage.add(pedalClick);
    oscP5.send(myMessage, myRemoteLocation);
    tP = 0;

    fill(255);
    ellipse(width*0.5, height*0.5, 200, 200);
  }
  else if (a.analogRead(0) == 0 && pedalClick == 1 && tP > 1) {
    pedalClick = 0;
    OscMessage myMessage = new OscMessage("/loop");
    myMessage.add(pedalClick);
    oscP5.send(myMessage, myRemoteLocation);
  }
  tP += 0.02;
}

// OSC control functions //////////////////////////////////////////////

void oscEvent(OscMessage theOscMessage) 
{  
  // get distance value
  if (theOscMessage.checkAddrPattern("/distance")) {
    message = theOscMessage.get(0).floatValue();
    messageHold = map(message, maxLeft, maxRight, 0, width);
    displaceField(messageHold);
  }

  // get kicked value
  if (theOscMessage.checkAddrPattern("/kick")) {
    if (theOscMessage.get(0).intValue() == 1) {
      kick();
    }
  }

  // get clapped value
  if (theOscMessage.checkAddrPattern("/clap")) {
    if (theOscMessage.get(0).intValue() == 1) {

      snapped = true;
      snaps.clear();
      for (int i = 0; i < 5; i++) {
        snaps.add(new ChainBreak(chains.get(i)));
      }
    }
  }
}

void sendKeyChange() {
  OscMessage myMessage = new OscMessage("/key");
  myMessage.add(currentKey);
  oscP5.send(myMessage, myRemoteLocation);
}

void sendReverb() {
  if (getFingerPos(4) != null) {
    reverb = constrain(map(getFingerPos(0).z, 50, 220, 0, 1), 0, 1);
    OscMessage myMessage = new OscMessage("/reverb");
    myMessage.add(reverb);
    oscP5.send(myMessage, myRemoteLocation);
  }
}

void sendHiFilter() {
  OscMessage myMessage = new OscMessage("/hiPass");
  myMessage.add(hiPass);
  oscP5.send(myMessage, myRemoteLocation);
}

void sendLowFilter() {
  OscMessage myMessage = new OscMessage("/lowPass");
  myMessage.add(lowPass);
  oscP5.send(myMessage, myRemoteLocation);
}


// key functions //////////////////////////////////////////////

void changeKey() {
  if (getFingerPos(2) != null) {

    fill(140, 255, 200);
    textFont(font, 350);

    if (!aeolian) {
      fingY = map(getFingerPos(0).z, 50, 200, 48, 52);
      currentKey = (int)fingY;
      text(keys[currentKey%12], width*0.5, height*0.5);
      sendKeyChange();
    }
    else {
      fingY = map(getFingerPos(0).z, 80, 230, 24, 28);
      octaveShift = (int)((fingY)/7);
      currentKey = 12 + octaveShift*12 + aeolianNum[((int)fingY)%7];
      text(aeolianKey[(int)fingY%7], width*0.5, height*0.5);
      sendKeyChange();
    }
  }
}

void initialiseKeys() {

  // initialise list of chromatic keys
  keys[0] = "C";
  keys[1] = "C#";
  keys[2] = "D";
  keys[3] = "D#";
  keys[4] = "E";
  keys[5] = "F";
  keys[6] = "F#";
  keys[7] = "G";
  keys[8] = "G#";
  keys[9] = "A";
  keys[10] = "Bb";
  keys[11] = "B";

  // initialise Aeolian keys

  aeolianNum[0] = 9;
  aeolianNum[1] = 11;
  aeolianNum[2] = 12;
  aeolianNum[3] = 14;
  aeolianNum[4] = 16;
  aeolianNum[5] = 17;
  aeolianNum[6] = 19;

  aeolianKey[0] = keys[(9+transpose)%12];
  aeolianKey[1] = keys[(11+transpose)%12];
  aeolianKey[2] = keys[transpose%12];
  aeolianKey[3] = keys[(2+transpose)%12];
  aeolianKey[4] = keys[(4+transpose)%12];
  aeolianKey[5] = keys[(5+transpose)%12];
  aeolianKey[6] = keys[(7+transpose)%12];
}

void transposeKeys() {
  if (transpose < 0) transpose = 0;
  aeolianKey[0] = keys[(8+transpose)%12];
  aeolianKey[1] = keys[(10+transpose)%12];
  aeolianKey[2] = keys[transpose%12];
  aeolianKey[3] = keys[(2+transpose)%12];
  aeolianKey[4] = keys[(4+transpose)%12];
  aeolianKey[5] = keys[(5+transpose)%12];
  aeolianKey[6] = keys[(7+transpose)%12];
}

// leap functions //////////////////////////////////////////////

void fingerControl() {

  // if 5 fingers control reverb

  if (leap.getFingerList().size() == 5) {
    sendReverb();
  }

  // if 4 fingers

  // if 3 fingers change key

  if (leap.getFingerList().size() == 3) {
    changeKey();
  }

  if (leap.getHandList().size() > 1 && leap.getFingerList().size() > 6) {
    hiPass = PVector.dist(leap.getPosition(leap.getHand(0)), (leap.getPosition(leap.getHand(1))));
    hiPass = constrain(map(hiPass, 400, 1600, 0, 127), 0, 127);
    sendHiFilter();
  }


  if (leap.getFingerList().size() == 1) {
    lowPass = leap.getPosition(leap.getHand(0)).y;
    lowPass = constrain(map(lowPass, 350, 0, 0, 127), 0, 127);
    sendLowFilter();

  }
}

public PVector getFingerPos(int fingerNum) {

  // finger pos is calibrated to sit within grid
  try {
    fingerPos = leap.getTip(leap.getFinger(fingerNum));
  } 
  catch (Exception e) {
    if ( fingerNum - 1 > 0) {
      fingerPos = leap.getTip(leap.getFinger(fingerNum-1));
    }
    else {
      return(new PVector(0, 0, 1000));
    }
  }

  fingerPos.set((fingerPos.x - 580) * scaleFactor, 
                (fingerPos.z )  * scaleFactor * height / width, 
                (-fingerPos.y + 677)  * scaleFactor);
  return (fingerPos);
}

void drawAllFingers() {
  for (int i = 0; i < leap.getFingerList().size(); i++) {
    if (getFingerPos(i) == null) {
      if ( i != leap.getFingerList().size() - 1) {
        drawFinger(getFingerPos(i));
      }
    }
    else {
      drawFinger(getFingerPos(i));
    }
  }
}

public void drawFinger(PVector fingerPos) {
  pushMatrix();
  translate(2*fingerPos.x + width*0.5, height - 2*fingerPos.z - 40);
  noStroke();
  fill(0);
  ellipse(0, 0, 20, 20);
  popMatrix();
}

public void stop() {
  leap.stop();
}

/////////////////////////////////////////////////////////////////////////////////////////////


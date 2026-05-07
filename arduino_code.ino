// --- Musical Notes ---
#define NOTE_G4  392
#define NOTE_AS4 466
#define NOTE_C5  523
#define NOTE_F4  349
#define NOTE_FS4 370
#define NOTE_B5  988
#define NOTE_E6  1319
#define NOTE_G5  784
#define NOTE_C6  1047

// Pin Mapping
const int btnLayer   = 2;  
const int btnReset   = 3;  
const int btnSave    = 4;  
const int buzzerPin  = 8;  

int currentLayer = 1; 
bool lastLayerBtnState = HIGH;
bool lastResetBtnState = HIGH;
bool lastSaveBtnState  = HIGH;

void setup() {
  Serial.begin(115200);
  pinMode(btnLayer, INPUT_PULLUP);
  pinMode(btnReset, INPUT_PULLUP);
  pinMode(btnSave, INPUT_PULLUP);
  pinMode(buzzerPin, OUTPUT);
}

// --- MELODIES ---
void playMissionImpossible() {
  int melody[] = {NOTE_G4, NOTE_G4, NOTE_AS4, NOTE_C5, NOTE_G4, NOTE_G4, NOTE_F4, NOTE_FS4};
  int durations[] = {150, 150, 150, 150, 150, 150, 150, 150};
  for (int i = 0; i < 8; i++) {
    tone(buzzerPin, melody[i], durations[i]);
    delay(durations[i] * 1.3);
  }
  noTone(buzzerPin);
}

void playCoin() {
  tone(buzzerPin, NOTE_B5, 100);
  delay(100);
  tone(buzzerPin, NOTE_E6, 250);
  delay(250);
  noTone(buzzerPin);
}

void playMarioReset() {
  int melody[] = {NOTE_G4, NOTE_C5, NOTE_E6, NOTE_G5, NOTE_C6, NOTE_E6};
  int durations[] = {80, 80, 80, 80, 80, 150};
  for (int i = 0; i < 6; i++) {
    tone(buzzerPin, melody[i], durations[i]);
    delay(durations[i] * 1.1);
  }
  noTone(buzzerPin);
}

void loop() {
  // Read Potentiometers
  int p1 =  analogRead(A0);
  int p2 =  analogRead(A1);
  int p3 =  analogRead(A2);
  int p4 =  analogRead(A3);

  // Read Buttons
  bool layerRead = digitalRead(btnLayer);
  bool resetRead = digitalRead(btnReset);
  bool saveRead  = digitalRead(btnSave);

  // --- Button 1: Layer Logic (Toggle) ---
  if (layerRead == LOW && lastLayerBtnState == HIGH) {
    currentLayer = (currentLayer == 1) ? 0 : 1; // Properly toggle between 0 and 1
    playCoin();
  }
  lastLayerBtnState = layerRead;

  // --- Button 2: Reset Logic (Edge Detection) ---
  if (resetRead == LOW && lastResetBtnState == HIGH) {
    playMarioReset(); 
  }
  lastResetBtnState = resetRead;

  // --- Button 3: Save Logic (Edge Detection) ---
  if (saveRead == LOW && lastSaveBtnState == HIGH) {
    playMissionImpossible();
  }
  lastSaveBtnState = saveRead;

  // Serial Packet: P1,P2,P3,P4,SaveState,LayerID,ResetState
  Serial.print(p1);        Serial.print(",");
  Serial.print(p2);        Serial.print(",");
  Serial.print(p3);        Serial.print(",");
  Serial.print(p4);        Serial.print(",");
  Serial.print(!saveRead);  Serial.print(","); // Sends 1 if pressed
  Serial.print(currentLayer); Serial.print(",");
  Serial.println(!resetRead); // Sends 1 if pressed

  delay(20);
}

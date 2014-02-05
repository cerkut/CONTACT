
class Field {

  PVector[][] pts;
  PVector trans;

  float dist;
  float timer;
  int spacing;

  int w;
  int h;

  Field(int _spacing) {

    spacing = _spacing;
    timer = 0;
    dist = 0;
    w = width/spacing +2;
    h = height/spacing +1;
    pts = new PVector[w][h];
    trans = new PVector(0, 0);

    for (int i = 0; i < w; i++) {
      for (int j =0; j < h; j ++) {
        pts[i][j] = new PVector(i*spacing, j*spacing);
      }
    }
  }

  void changeSpacing(int newSpacing) {
    w = width/newSpacing +2;
    h = height/newSpacing +2;

    pts = new PVector[w][h];

    for (int i = 0; i < w; i++) {
      for (int j =0; j < h; j ++) {
        pts[i][j] = new PVector(i*newSpacing, j*newSpacing);
      }
    }

    spacing = newSpacing;
  }


  void update(PVector mse) {
    for (int i = 0; i < w; i++) {
      for (int j =0; j < h; j ++) {
        pts[i][j] = new PVector(i*spacing, j*spacing);
        dist = constrain(dist(pts[i][j].x, pts[i][j].y, mse.x, mse.y), spacing, 2000);
        trans.set(PVector.sub(pts[i][j], mse));
        trans.normalize();
        trans.mult(timer*sin(timer)*1000/dist);
        pts[i][j].add(trans);
      }
    }
    timer -= 0.2;
  }

  void display() {
    strokeWeight(1);
    for (int i = 0; i < w; i++) {
      for (int j =0; j < h; j ++) {
        dist = constrain(dist(pts[i][j].x, pts[i][j].y, i*spacing, j*spacing), 0, 255);
        stroke(255 - dist*7, dist*7, 20 + dist*7);
        if (dist*7 < 5) stroke(100, 100);
        if (i < w-1) line(pts[i][j].x, pts[i][j].y, pts[i+1][j].x, pts[i+1][j].y);
        if (j < h-1) line(pts[i][j].x, pts[i][j].y, pts[i][j+1].x, pts[i][j+1].y);
      }
    }
  }
}


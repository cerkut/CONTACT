class ChainBreak {

  ArrayList<VerletParticle2D> p1;
  ArrayList<VerletParticle2D> p2;

  ArrayList<Vec2D> vels;
  
  float[] randoms;
  
  Chain chain;

  ChainBreak(Chain _chain) {
    
    chain = _chain;

    p1 = new ArrayList<VerletParticle2D>();
    p2 = new ArrayList<VerletParticle2D>();

    vels = new ArrayList<Vec2D>();
    
    randoms = new float[chain.particles.size()];

    for (int i = 0; i < chain.particles.size(); i ++) {
      randoms[i] = random(0.8,3);
      p1.add(new VerletParticle2D(chain.particles.get(i)));
      vels.add(new Vec2D(chain.particles.get(i).getVelocity().scale(randoms[i])));
      if (i < chain.particles.size()-1) {
        p2.add(new VerletParticle2D(chain.particles.get(i+1)));
      }
    }
  }

  void update() {

    for (int i = 0; i < p1.size(); i ++) {
      p1.get(i).addSelf(vels.get(i));
      if (i < chain.particles.size()-1) {
        p2.get(i).addSelf(vels.get(i));
      }
    }
  }

  void display() {
    for (int i = 0; i < p1.size()-1; i ++) {
      stroke(p1.get(i).y / 5 ,255,255,255-255*tS);
      line(p1.get(i).x, p1.get(i).y, p2.get(i).x, p2.get(i).y);
    }
  }
}


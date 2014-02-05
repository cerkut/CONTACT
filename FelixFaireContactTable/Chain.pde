
class Chain {

  // Chain properties
  float totalLength;  // How long
  int numPoints;      // How many points
  float strength;     // Strength of springs

  ArrayList<Particle> particles;
  ArrayList<VerletSpring2D> springs;

  // Chain constructor
  Chain(float l, int n, float s) {
    
    particles = new ArrayList<Particle>();
    springs = new ArrayList<VerletSpring2D>();

    totalLength = l;
    numPoints = n;
    strength = s;

    float len = totalLength / numPoints;


    for (int i=0; i < numPoints+1; i++) {

      Particle particle=new Particle(i*len, height*0.5);

      physics.addParticle(particle);
      particles.add(particle);

      // Connect the particles with a Spring (except for the head)
      if (i != 0) {
        Particle previous = particles.get(i-1);
        VerletSpring2D spring = new VerletSpring2D(particle, previous, len*0.95, strength);
        // Add the spring to the physics world
        physics.addSpring(spring);
        springs.add(spring);
      }
    }

    // Keep the top fixed
    Particle head=particles.get(0);
    head.lock();
    
    Particle tail = particles.get(numPoints);
    tail.lock();

  }


  void display() {
    // Draw line connecting all points
    beginShape();
    stroke(255);
    strokeWeight(4);
    noFill();
    for (Particle p : particles) {
      vertex(p.x, p.y);
    }
    endShape();
  }
}


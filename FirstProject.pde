

//Liste af alle entities. Når en entity er oprettet, er den tilføjet til denne liste i sin constructor.
ArrayList<Entity> entityList = new ArrayList<Entity>();

//Når en screen er initialized er den tilføjet til screenList
ArrayList<Screen> screenList = new ArrayList<Screen>();

//KeyInputs er en liste af alle taster der er pressed.
ArrayList<Character> keyInputs = new ArrayList<Character>();


/*
Vi bruger kun vores default skærm til at udregne ting, vi tegner den ikke, da vi ønsker at have de screens vi bruger som et Screen objekt.
*/
void setup()
{

    //Her gør vi default skærmen usynlig.
    getSurface().setVisible(false);

    //Vi opretter 3 skærme udfra midten af skærmen.
    for (int i = 0; i < 3; i++)
    {
        Screen screen = new EntityScreen();
        screen.init();
        screen.getSurface().setLocation(displayWidth/3*i, displayHeight/ 1/3);
    }

    //Vi opretter spilleren
    new Player(displayWidth/2, displayHeight/2, 30,30);

    //Demonstration af hvor nemt det er at tilføje flere spillere, med deres egen unikke styring.
    new Player(displayWidth/2+30, displayHeight/2+30, 30,30)
    {
    public char UPKEY()
    {
        return 'u';
    }

    public char DOWNKEY()
    {
        return 'j';
    }

    public char RIGHTKEY()
    {
        return 'k';
    }

    public char LEFTKEY()
    {
        return 'h';
    }
    };
}


//Main thread
void draw()
{
    for (Entity entity : entityList)
    {
        //Vi tjekker om vores Entity implementerer Movement
        if (entity instanceof Movement)
        {

            //Vi tjekker om vores Entity implementerer InputMovement
            if (entity instanceof InputMovement)
            {

                //Vi tjekker alle vores InputMovements og sammenligner det med vores keyInput array. Vi bruger derfter move funktionen fra Movement.
                if (keyInputs.contains(((InputMovement) entity).UPKEY()))
                {
                    ((InputMovement) entity).move(Movement.Direction.UP);
                }
                if (keyInputs.contains(((InputMovement) entity).LEFTKEY()))
                {
                    ((InputMovement) entity).move(Movement.Direction.LEFT);
                }
                if (keyInputs.contains(((InputMovement) entity).DOWNKEY()))
                {
                    ((InputMovement) entity).move(Movement.Direction.DOWN);
                }
                if (keyInputs.contains(((InputMovement) entity).RIGHTKEY()))
                {
                    ((InputMovement) entity).move(Movement.Direction.RIGHT);
                }
            }
        }
    }    
}

//Vi opretter en ny screen. Vi extender PApplet, som kortsagt er Processing.
class Screen extends PApplet
{
    protected int height, width;

    public Screen(){this(600,600);}
    public Screen(int height, int width)
    {
        this.height=height;
        this.width=width;
    }

    void setup()
    {
        background(0);
    }

    public int getWidth()
    {
        return width;
    }

    public int getHeight()
    {
        return height;
    }

    //Vi bruger ikke PApplet's frame, da den ikke er afhænge af swing.JFrame, så den registere ikke ændringer der ikke kommer direkte fra Processing.
    //Nu kan vi få koordinaterne på vores Screen.
    protected javax.swing.JFrame getJFrame()
    {
        return (javax.swing.JFrame) ((processing.awt.PSurfaceAWT.SmoothCanvas) getSurface().getNative()).getFrame();
    }
    public float getX()
    {

        //Vi bruger ternary, hvis vores frame ikke vises, kan man ikke få koordinaterne.
        return getJFrame().isShowing()? (float)getJFrame().getLocationOnScreen().getX() : 0.0;
    }

    public float getY()
    {
        return getJFrame().isShowing()? (float)getJFrame().getLocationOnScreen().getY() : 0.0;
    }

    public void setX(float x)
    {
        setLocation(x, getX());
    }

    public void setY(float y)
    {
        setLocation(getX(), y);
    }

    public void setLocation(float x, float y)
    {
        getSurface().setLocation(Math.round(x),Math.round(y));
    }

    void settings()
    {
        size(width, height);
    }

    public void init()
    {
        PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
        screenList.add(this);
    }

    //Vi registerer taster der bliver tastet og tilføjer dem til vores keyInput array, hvis de ikke allerede er i listen.
    void keyPressed(KeyEvent e)
    {
        if (!keyInputs.contains(e.getKey()))
        {
            keyInputs.add(e.getKey());
        }
    }

    //Når en key bliver released, fjerner vi den fra vores keyInput array.
    void keyReleased(KeyEvent e)
    {
        if (keyInputs.contains(e.getKey()))
        {
            ArrayList<Character> tempKeys = new ArrayList<Character>();
            for (Character key : keyInputs)
            {
                if (key != e.getKey())
                {
                    tempKeys.add(key);
                }
            }
            keyInputs = tempKeys;
        }
    }
}

//EntityScreen extends Screen. Den er lavet til at håndtere entities.
class EntityScreen extends Screen
{

    float lastX, lastY;
    boolean moved = false;

    void draw()
    {
        if (lastX != getX() || lastY != getY())
        {
            moved = true;
        }
        clear();
        
        
        for (Entity entity : entityList)
        {
            if (moved)
            {

                //Hvis skærmen bliver flyttet, så vores entity ikke har en skærm at blive tegnet på, så ville vi 
                //flytte skærmen tilbage til dens tidligere position, så at vores entity kan blive tegnet.
                //Pga. sådan som vinduer fungerer, så ser det ikke super godt ud og kan være lidt clunky.
                if (entity.getWithinScreens().isEmpty())
                {
                    setLocation(lastX, lastY);
                }
            }
            entity.draw(this);
        }

        lastX = getX();
        lastY = getY();
        moved = false;
    }
}

//Abstract, da vi ikke ønsker at have en tom entity.
abstract class Entity
{
    float x, y, width, height;

    {
        entityList.add(this);
    }

    public Entity(float x, float y, float width, float height)
    {
        this.x=x;
        this.y=y;
        this.height=height;
        this.width=width;
    }

    //Vi tjekker om vores Entities' koordinater er indenfor en skærm.
    public boolean withinScreen(Screen screen)
    {
        return (x >= screen.getX() && x+width <= screen.getX()+screen.getWidth()) && (y >= screen.getY() && y+height <= screen.getY()+screen.getHeight());
    }

    //Den her funktion er god til at finde ud af om vores Entity bliver vidst på nogle skærme. Bruger det ofte til at se om spilleren kan bevæge sig.
    public ArrayList<Screen> getWithinScreens()
    {
        ArrayList<Screen> screens = new ArrayList<Screen>();
        for (Screen screen : screenList)
        {
            if (withinScreen(screen))
            {
                screens.add(screen);
            }
        }
        return screens;
    }

    public float getX()
    {
        return x;
    }

    public float getY()
    {
        return y;
    }

    public void setX(float x)
    {
        this.x=x;
    }

    public void setY(float y)
    {
        this.y=y;
    }
    public abstract void draw(Screen screen);
}

interface Movement
{
    public float getSpeed();
    public void move(Direction direction);
    

    //Vi opretter en Direction enum til at holde styr på de forskellige movement directions
    enum Direction
    {
        UP(0, -1), DOWN(0, 1), RIGHT(1, 0), LEFT(-1, 0);

        int y, x;
        Direction(int x, int y)
        {
            this.x=x;
            this.y=y;
        }

        public int getX()
        {
            return this.x;
        }

        public int getY()
        {
            return this.y;
        }

    }
}


/*
Jeg har lavet InputMovement en ting, så hvis det skulle være, ville jeg nemt kunne tilføje flere entities der bruger inputs til at bevæge sig.
*/
interface InputMovement extends Movement
{
    public char UPKEY();
    public char DOWNKEY();
    public char RIGHTKEY();
    public char LEFTKEY();
}

class Player extends Entity implements InputMovement
{
    public Player(float x, float y, float width, float height)
    {
        super(x,y,width,height);
    }

    public float getSpeed()
    {
        return 5.0f;
    }

    public void move(Direction dir)
    {

        //Grunden til at vi laver et tjek hver gang, er hvis koordinaterne er udenfor skærmen, så skal det flyttes.
        //Grunden til at den er blevet spilltet op til x og y, istedet for at håndterer dem på samme tid, er at vi ikke ville sætte X tilbage hvis det kun er Y der er ugyldig.
        y += dir.getY()*getSpeed();
        if (getWithinScreens().isEmpty())
        {
            y -= dir.getY()*getSpeed();
        }

        x += dir.getX()*getSpeed();
        if (getWithinScreens().isEmpty())
        {
            x -= dir.getX()*getSpeed();
        }
    }

    public char UPKEY()
    {
        return 'w';
    }

    public char DOWNKEY()
    {
        return 's';
    }

    public char RIGHTKEY()
    {
        return 'd';
    }

    public char LEFTKEY()
    {
        return 'a';
    }

    public void draw(Screen screen)
    {
        screen.fill(255);
        screen.rect(x-screen.getX(),y-screen.getY(),width,height);
    }
}


// Each card is represented as a bitmask with a single bit set
// 2c = 1 << 0 ... Ad = 1 << 51
typedef long card_t;

int score7(card_t c1, card_t c2, card_t c3, card_t c4, card_t c5, card_t c6, card_t c7);
int score5(card_t c1, card_t c2, card_t c3, card_t c4, card_t c5);

static int HIGHCARD = 0;
static int PAIR = 1 << 26;
static int TWOPAIR = 2 << 26;
static int TRIP = 3 << 26;
static int STRAIGHT = 4 << 26;
static int FLUSH  = 5 << 26;
static int FULLHOUSE = 6 << 26;
static int QUAD = 7 << 26;
static int STRAIGHTFLUSH = 8 << 26;

static char* HAND_NAMES[] = {"HIGHCARD", "PAIR", "TWOPAIR", "TRIP",
    "STRAIGHT", "FLUSH", "FULLHOUSE", "QUAD",
    "STRAIGHTFLUSH"};

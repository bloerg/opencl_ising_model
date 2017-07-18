
#ifdef __DO_FLOAT__
#define tfloat float
#else
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#define tfloat double
#endif

#define HALF 0.5
#define ZERO 0.0
#define ONE  1.0
#define TWO  2.0

// scaling factor 2^32
#define DIVISOR 4294967296.0

#ifndef M_PI
#define M_PI 3.14159265358979
#endif

#define UINT_THIRTY 30U
#define UINT_BIG_CONST 1812433253U


// Mersenne twister algorithm constants. Please refer for details
// http://en.wikipedia.org/wiki/Mersenne_twister
// Matsumoto, M.; Nishimura, T. (1998). "Mersenne twister: a 623-dimensionally equidistributed uniform pseudo-random number generator".
// ACM Transactions on Modeling and Computer Simulation 8 (1)

// degree of Mersenne twister recurrence
#define N 624
// middle word
#define M 397

// Mersenne twister constant 2567483615
#define MATRIX_A 0x9908B0DFU
// Mersenne twister constant 2636928640
#define MASK_B 0x9D2C5680U
// Mersenne twister constant 4022730752
#define MASK_C 0xEFC60000U
// Mersenne twister tempering shifts
#define SHIFT_U 11
#define SHIFT_S 7
#define SHIFT_T 15
#define SHIFT_L 18



__kernel void ising(__global float* lattice) {

    // Global ID
    int tid;

    // Get global id = index of put&call options pair to be calculated
    tid = get_global_id(0);


    // Precalculate auxiliary variables
    tfloat int_to_float_normalize_factor = ONE/((tfloat)DIVISOR); // for float random number scaling

    // State indeces
    int i, iCurrentMiddle, iCurrent;
    // Mersenne twister generated random number
    unsigned int mt_rnd_num;
    // State of the MT generator
    int mt_state[N];
    // Temporary state for MT states swap
    int tmp_mt;

    // set seed
    mt_state[0] = 1234; 
    //~ mt_state[0] = tid;


    // Initialize the MT generator from a seed
    for (i = 1; i < N; i++)
    {
        mt_state[i] = (unsigned int)i + UINT_BIG_CONST * (mt_state[i - 1] ^ (mt_state[i - 1] >> UINT_THIRTY));
    }

    // Initialize MT state
    i = 0;
    tmp_mt = mt_state[0];

    int NSAMP = 16;


    for (int iSample = 0; iSample < NSAMP; iSample = iSample + 2) // Generate two samples per iteration as it is convinient for Box-Muller
    {
        // Mersenne twister loops generating untempered and tempered values in original description merged here together with Box-Muller
        // normally distributed random numbers generation and Black&Scholes formula.

        // First MT random number generation
        // Calculate new state indexes
        iCurrent = (iCurrent == N - 1) ?  0 : i + 1;
        iCurrentMiddle = (i + M >= N) ? i + M - N : i + M;

        mt_state[i] = tmp_mt;
        tmp_mt = mt_state[iCurrent];

        // MT recurrence
        // Generate untempered numbers
        mt_rnd_num = (mt_state[i] & 0x80000000U) | (mt_state[iCurrent] & 0x7FFFFFFFU);
        mt_rnd_num = mt_state[iCurrentMiddle] ^ (mt_rnd_num >> 1) ^ ((0-(mt_rnd_num & 1))& MATRIX_A);

        mt_state[i] = mt_rnd_num;

        // Tempering pseudorandom number
        mt_rnd_num ^= (mt_rnd_num >> SHIFT_U);
        mt_rnd_num ^= (mt_rnd_num << SHIFT_S) & MASK_B;
        mt_rnd_num ^= (mt_rnd_num << SHIFT_T) & MASK_C;
        mt_rnd_num ^= (mt_rnd_num >> SHIFT_L);

        tfloat rnd_num = (tfloat)mt_rnd_num;

        i = iCurrent;

        // Second MT random number generation
        // Calculate new state indexes
        iCurrent = (iCurrent == N - 1) ?  0 : i + 1;
        iCurrentMiddle = (i + M >= N) ? i + M - N : i + M;

        mt_state[i] = tmp_mt;
        tmp_mt = mt_state[iCurrent];

        // MT recurrence
        // Generate untempered numbers
        mt_rnd_num = (mt_state[i] & 0x80000000U) | (mt_state[iCurrent] & 0x7FFFFFFFU);
        mt_rnd_num = mt_state[iCurrentMiddle] ^ (mt_rnd_num >> 1) ^ ((0-(mt_rnd_num & 1))& MATRIX_A);


        mt_state[i] = mt_rnd_num;


        // Tempering pseudorandom number
        mt_rnd_num ^= (mt_rnd_num >> SHIFT_U);
        mt_rnd_num ^= (mt_rnd_num << SHIFT_S) & MASK_B;
        mt_rnd_num ^= (mt_rnd_num << SHIFT_T) & MASK_C;
        mt_rnd_num ^= (mt_rnd_num >> SHIFT_L);

        tfloat rnd_num1 = (tfloat)mt_rnd_num;

        i = iCurrent;

        // Make uniform random variables in (0,1] range
        rnd_num = (rnd_num + ONE) * int_to_float_normalize_factor;
        rnd_num1 = (rnd_num1 + ONE) * int_to_float_normalize_factor;

        // Generate normally distributed random numbers
        // Box-Muller
        //~ tfloat tmp_bm = sqrt(std::max(-TWO*log(rnd_num), 0.0)); // max added to be sure that sqrt argument non-negative
        tfloat tmp_bm = sqrt(max(-TWO*log(rnd_num), 0.0)); // max added to be sure that sqrt argument non-negative
        rnd_num = tmp_bm*cos(TWO*M_PI*rnd_num1);
        rnd_num1 = tmp_bm*sin(TWO*M_PI*rnd_num1);
        
        lattice[iSample] = rnd_num;
        lattice[iSample + 1] = rnd_num1;
        
    }
    

}

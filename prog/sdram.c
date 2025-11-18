// This file is Copyright (c) 2013-2020 Florent Kermarrec <florent@enjoy-digital.fr>
// This file is Copyright (c) 2013-2014 Sebastien Bourdeauducq <sb@m-labs.hk>
// This file is Copyright (c) 2018 Chris Ballance <chris.ballance@physics.ox.ac.uk>
// This file is Copyright (c) 2018 Dolu1990 <charles.papon.90@gmail.com>
// This file is Copyright (c) 2019 Gabriel L. Somlo <gsomlo@gmail.com>
// This file is Copyright (c) 2018 Jean-François Nguyen <jf@lambdaconcept.fr>
// This file is Copyright (c) 2018 Sergiusz Bazanski <q3k@q3k.org>
// This file is Copyright (c) 2018 Tim 'mithro' Ansell <me@mith.ro>
// This file is Copyright (c) 2021 Antmicro <www.antmicro.com>
// License: BSD

#include <generated/csr.h>
#include <generated/sdram_phy.h>
#include <generated/mem.h>

unsigned long lfsr(unsigned long bits, unsigned long prev)
{
    unsigned long lsb = prev & 1;

    prev >>= 1;
    prev ^= (-lsb) & 0x80200003;

    return prev;
}

void read_inc_dq_delay(int module) {
	ddrphy_rdly_dq_inc_write(1);
}

void read_rst_dq_delay(int module) {
	ddrphy_rdly_dq_rst_write(1);
}

void read_inc_dq_bitslip(int module) {
	ddrphy_rdly_dq_bitslip_write(1);
}

void read_rst_dq_bitslip(int module) {
	ddrphy_rdly_dq_bitslip_rst_write(1);
}

typedef void (*action_callback)(int module);
void sdram_leveling_action(int module, int dq_line, action_callback action) {
	*(volatile uint32_t *)CSR_DDRPHY_DLY_SEL_ADDR = 1 << module;
	action(module);
	*(volatile uint32_t *)CSR_DDRPHY_DLY_SEL_ADDR = 0;
}

#define DQ_COUNT 1

/*-----------------------------------------------------------------------*/
/* Constants                                                             */
/*-----------------------------------------------------------------------*/
#define DFII_PIX_DATA_BYTES SDRAM_PHY_DFI_DATABITS/8

/*-----------------------------------------------------------------------*/
/* DFII                                                                  */
/*-----------------------------------------------------------------------*/
static unsigned char sdram_dfii_get_rdphase(void) {
	return ddrphy_rdphase_read();
}

static unsigned char sdram_dfii_get_wrphase(void) {
	return ddrphy_wrphase_read();
}

static void sdram_dfii_pix_address_write(unsigned char phase, unsigned int value) {
	switch (phase) {
	case 3: sdram_dfii_pi3_address_write(value); break;
	case 2: sdram_dfii_pi2_address_write(value); break;
	case 1: sdram_dfii_pi1_address_write(value); break;
	default: sdram_dfii_pi0_address_write(value);
	}
}

static void sdram_dfii_pird_address_write(unsigned int value) {
	unsigned char rdphase = sdram_dfii_get_rdphase();
	sdram_dfii_pix_address_write(rdphase, value);
}

static void sdram_dfii_piwr_address_write(unsigned int value) {
	unsigned char wrphase = sdram_dfii_get_wrphase();
	sdram_dfii_pix_address_write(wrphase, value);
}

static void sdram_dfii_pix_baddress_write(unsigned char phase, unsigned int value) {
	switch (phase) {
	case 3: sdram_dfii_pi3_baddress_write(value); break;
	case 2: sdram_dfii_pi2_baddress_write(value); break;
	case 1: sdram_dfii_pi1_baddress_write(value); break;
	default: sdram_dfii_pi0_baddress_write(value);
	}
}

static void sdram_dfii_pird_baddress_write(unsigned int value) {
	unsigned char rdphase = sdram_dfii_get_rdphase();
	sdram_dfii_pix_baddress_write(rdphase, value);
}

static void sdram_dfii_piwr_baddress_write(unsigned int value) {
	unsigned char wrphase = sdram_dfii_get_wrphase();
	sdram_dfii_pix_baddress_write(wrphase, value);
}

static void command_px(unsigned char phase, unsigned int value) {
	switch (phase) {
	case 3: command_p3(value); break;
	case 2: command_p2(value); break;
	case 1: command_p1(value); break;
	default: command_p0(value);
	}
}

static void command_prd(unsigned int value) {
	unsigned char rdphase = sdram_dfii_get_rdphase();
	command_px(rdphase, value);
}

static void command_pwr(unsigned int value) {
	unsigned char wrphase = sdram_dfii_get_wrphase();
	command_px(wrphase, value);
}

/*-----------------------------------------------------------------------*/
/*  Mode Register                                                        */
/*-----------------------------------------------------------------------*/

__attribute__((unused)) static int swap_bit(int num, int a, int b) {
	if (((num >> a) & 1) != ((num >> b) & 1)) {
		num ^= (1 << a);
		num ^= (1 << b);
	}
	return num;
}

void sdram_mode_register_write(char reg, int value) {
#ifndef SDRAM_PHY_CLAM_SHELL
	sdram_dfii_pi0_address_write(value);
	sdram_dfii_pi0_baddress_write(reg);
	command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
#else
	sdram_dfii_pi0_address_write(value);
	sdram_dfii_pi0_baddress_write(reg);
	command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS_TOP);

	value = swap_bit(value, 3, 4);
	value = swap_bit(value, 5, 6);
	value = swap_bit(value, 7, 8);
	value = swap_bit(value, 11, 13);
	reg = swap_bit(reg, 0, 1);

	sdram_dfii_pi0_address_write(value);
	sdram_dfii_pi0_baddress_write(reg);
	command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS_BOTTOM);
#endif
}

/*-----------------------------------------------------------------------*/
/* Leveling Centering (Common for Read/Write Leveling)                   */
/*-----------------------------------------------------------------------*/

static void sdram_activate_test_row(void) {
	sdram_dfii_pi0_address_write(0);
	sdram_dfii_pi0_baddress_write(0);
	command_p0(DFII_COMMAND_RAS|DFII_COMMAND_CS);
	cdelay(15);
}

static void sdram_precharge_test_row(void) {
	sdram_dfii_pi0_address_write(0);
	sdram_dfii_pi0_baddress_write(0);
	command_p0(DFII_COMMAND_RAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
	cdelay(15);
}

// Count number of bits in a 32-bit word, faster version than a while loop
// see: https://www.johndcook.com/blog/2020/02/21/popcount/
static unsigned int popcount(unsigned int x) {
	x -= ((x >> 1) & 0x55555555);
	x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
	x = (x + (x >> 4)) & 0x0F0F0F0F;
	x += (x >> 8);
	x += (x >> 16);
	return x & 0x0000003F;
}

static void print_scan_errors(unsigned int errors) {
}

#define READ_CHECK_TEST_PATTERN_MAX_ERRORS (8*SDRAM_PHY_PHASES*DFII_PIX_DATA_BYTES/SDRAM_PHY_MODULES)
#define MODULE_BITMASK ((1<<SDRAM_PHY_DQ_DQS_RATIO)-1)

static unsigned int sdram_write_read_check_test_pattern(int module, unsigned int seed, int dq_line) {
	int p, i, bit;
	unsigned int errors;
	unsigned int prv;
	unsigned char value;
	unsigned char tst[DFII_PIX_DATA_BYTES];
	unsigned char prs[SDRAM_PHY_PHASES][DFII_PIX_DATA_BYTES];

	/* Generate pseudo-random sequence */
	prv = seed;
	for(p=0;p<SDRAM_PHY_PHASES;p++) {
		for(i=0;i<DFII_PIX_DATA_BYTES;i++) {
			value = 0;
			for (bit=0;bit<8;bit++) {
				prv = lfsr(32, prv);
				value |= (prv&1) << bit;
			}
			prs[p][i] = value;
		}
	}

	/* Activate */
	sdram_activate_test_row();

	/* Write pseudo-random sequence */
	for(p=0;p<SDRAM_PHY_PHASES;p++) {
		csr_wr_buf_uint8(sdram_dfii_pix_wrdata_addr(p), prs[p], DFII_PIX_DATA_BYTES);
	}
	sdram_dfii_piwr_address_write(0);
	sdram_dfii_piwr_baddress_write(0);
	command_pwr(DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS|DFII_COMMAND_WRDATA);
	cdelay(15);

#if defined(SDRAM_PHY_ECP5DDRPHY) || defined(SDRAM_PHY_GW2DDRPHY)
	ddrphy_burstdet_clr_write(1);
#endif // defined(SDRAM_PHY_ECP5DDRPHY) || defined(SDRAM_PHY_GW2DDRPHY)

	/* Read/Check pseudo-random sequence */
	sdram_dfii_pird_address_write(0);
	sdram_dfii_pird_baddress_write(0);
	command_prd(DFII_COMMAND_CAS|DFII_COMMAND_CS|DFII_COMMAND_RDDATA);
	cdelay(15);

	/* Precharge */
	sdram_precharge_test_row();

	errors = 0;
	for(p=0;p<SDRAM_PHY_PHASES;p++) {
		/* Read back test pattern */
		csr_rd_buf_uint8(sdram_dfii_pix_rddata_addr(p), tst, DFII_PIX_DATA_BYTES);
		/* Verify bytes matching current 'module' */
		int pebo;   // module's positive_edge_byte_offset
		int nebo;   // module's negative_edge_byte_offset, could be undefined if SDR DRAM is used
		int ibo;    // module's in byte offset (x4 ICs)
		int mask;   // Check data lines

		mask = MODULE_BITMASK;

#ifdef SDRAM_DELAY_PER_DQ
		mask = 1 << dq_line;
#endif // SDRAM_DELAY_PER_DQ

		/* Values written into CSR are Big Endian */
		/* SDRAM_PHY_XDR is define 1 if SDR and 2 if DDR*/
		nebo = (DFII_PIX_DATA_BYTES / SDRAM_PHY_XDR) - 1 - (module * SDRAM_PHY_DQ_DQS_RATIO)/8;
		pebo = nebo + DFII_PIX_DATA_BYTES / SDRAM_PHY_XDR;
		/* When DFII_PIX_DATA_BYTES is 1 and SDRAM_PHY_XDR is 2, pebo and nebo are both -1s,
		* but only correct value is 0. This can happen when single x4 IC is used */
		if ((DFII_PIX_DATA_BYTES/SDRAM_PHY_XDR) == 0) {
			pebo = 0;
			nebo = 0;
		}

		ibo = (module * SDRAM_PHY_DQ_DQS_RATIO)%8; // Non zero only if x4 ICs are used

		errors += popcount(((prs[p][pebo] >> ibo) & mask) ^
		                   ((tst[pebo] >> ibo) & mask));
		if (SDRAM_PHY_DQ_DQS_RATIO == 16)
			errors += popcount(((prs[p][pebo+1] >> ibo) & mask) ^
			                   ((tst[pebo+1] >> ibo) & mask));


#if SDRAM_PHY_XDR == 2
		if (DFII_PIX_DATA_BYTES == 1) // Special case for x4 single IC
			ibo = 0x4;
		errors += popcount(((prs[p][nebo] >> ibo) & mask) ^
		                   ((tst[nebo] >> ibo) & mask));
		if (SDRAM_PHY_DQ_DQS_RATIO == 16)
			errors += popcount(((prs[p][nebo+1] >> ibo) & mask) ^
			                   ((tst[nebo+1] >> ibo) & mask));
#endif // SDRAM_PHY_XDR == 2
	}

#if defined(SDRAM_PHY_ECP5DDRPHY) || defined(SDRAM_PHY_GW2DDRPHY)
	if (((ddrphy_burstdet_seen_read() >> module) & 0x1) != 1)
		errors += 1;
#endif // defined(SDRAM_PHY_ECP5DDRPHY) || defined(SDRAM_PHY_GW2DDRPHY)

	return errors;
}


static int run_test_pattern(int module, int dq_line) {
	int _seed_array[] = {42, 84, 36};
	int _seed_array_length = 3;
	int errors = 0;
	for (int i = 0; i < _seed_array_length; i++) {
		errors += sdram_write_read_check_test_pattern(module, _seed_array[i], dq_line);
	}
	return errors;
}

static void sdram_leveling_center_module(
	int module, int show_short, int show_long, action_callback rst_delay,
	action_callback inc_delay, int dq_line) {

	int i;
	int show;
	int working, last_working;
	unsigned int errors;
	int delay, delay_mid, delay_range;
	int delay_min = -1, delay_max = -1, cur_delay_min = -1;

	/* Find smallest working delay */
	delay = 0;
	working = 0;
	sdram_leveling_action(module, dq_line, rst_delay);
	while(1) {
		errors = run_test_pattern(module, dq_line);
		last_working = working;
		working = errors == 0;
		if(working && last_working && delay_min < 0) {
			delay_min = delay - 1; // delay on edges can be spotty
			break;
		}
		delay++;
		if(delay >= SDRAM_PHY_DELAYS)
			break;
		sdram_leveling_action(module, dq_line, inc_delay);
	}

	delay_max = delay_min;
	cur_delay_min = delay_min;
	/* Find largest working delay range */
	while(1) {
		errors = run_test_pattern(module, dq_line);
		working = errors == 0;
		if (working) {
			int cur_delay_length = delay - cur_delay_min;
			int best_delay_length = delay_max - delay_min;
			if (cur_delay_length > best_delay_length) {
				delay_min = cur_delay_min;
				delay_max = delay;
			}
		} else {
			cur_delay_min = delay + 1;
		}
		delay++;
		if(delay >= SDRAM_PHY_DELAYS)
			break;
		sdram_leveling_action(module, dq_line, inc_delay);
	}
	if(delay_max < 0) {
		delay_max = delay;
	}

	delay_mid   = (delay_min+delay_max)/2 % SDRAM_PHY_DELAYS;
	delay_range = (delay_max-delay_min)/2;

	/* Set delay to the middle and check */
	if (delay_min >= 0) {
		int retries = 8; /* Do N configs/checks and give up if failing */
		while (retries > 0) {
			/* Set delay. */
			sdram_leveling_action(module, dq_line, rst_delay);
			cdelay(100);
			for(i = 0; i < delay_mid; i++) {
				sdram_leveling_action(module, dq_line, inc_delay);
				cdelay(100);
			}

			/* Check */
			errors = run_test_pattern(module, dq_line);
			if (errors == 0)
				break;
			retries--;
		}
	}
}

/*-----------------------------------------------------------------------*/
/* Read Leveling                                                         */
/*-----------------------------------------------------------------------*/
static unsigned int sdram_read_leveling_scan_module(int module, int bitslip, int show, int dq_line) {
	int _seed_array_length = 3;
	unsigned int max_errors = _seed_array_length*READ_CHECK_TEST_PATTERN_MAX_ERRORS;
	int i;
	unsigned int score;
	unsigned int errors;

	/* Check test pattern for each delay value */
	score = 0;
	sdram_leveling_action(module, dq_line, read_rst_dq_delay);
	for(i=0;i<SDRAM_PHY_DELAYS;i++) {
		int working;
		errors = run_test_pattern(module, dq_line);
		working = errors == 0;
		/* When any scan is working then the final score will always be higher then if no scan was working */
		score += (working * max_errors*SDRAM_PHY_DELAYS) + (max_errors - errors);
		sdram_leveling_action(module, dq_line, read_inc_dq_delay);
	}

	return score;
}

void sdram_read_leveling(void) {
	int module;
	int bitslip;
	int dq_line = 0;
	unsigned int score;
	unsigned int best_score;
	int best_bitslip;

	for(module=0; module<SDRAM_PHY_MODULES; module++) {
		/* Scan possible read windows */
		best_score = 0;
		best_bitslip = 0;
		sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
		for(bitslip=0; bitslip<SDRAM_PHY_BITSLIPS; bitslip++) {
			/* Compute score */
			score = sdram_read_leveling_scan_module(module, bitslip, 1, dq_line);
			sdram_leveling_center_module(module, 1, 0, read_rst_dq_delay, read_inc_dq_delay, dq_line);
			if (score > best_score) {
				best_bitslip = bitslip;
				best_score = score;
			}
			/* Exit */
			if (bitslip == SDRAM_PHY_BITSLIPS-1)
				break;
			/* Increment bitslip */
			sdram_leveling_action(module, dq_line, read_inc_dq_bitslip);
		}

		/* Select best read window */
		sdram_leveling_action(module, dq_line, read_rst_dq_bitslip);
		for (bitslip=0; bitslip<best_bitslip; bitslip++)
			sdram_leveling_action(module, dq_line, read_inc_dq_bitslip);

		/* Re-do leveling on best read window*/
		sdram_leveling_center_module(module, 1, 0, read_rst_dq_delay, read_inc_dq_delay, dq_line);
	}
}

/*-----------------------------------------------------------------------*/
/* Initialization                                                        */
/*-----------------------------------------------------------------------*/

int sdram_init(void) {
	*(volatile uint32_t *)CSR_DDRPHY_RDPHASE_ADDR = SDRAM_PHY_RDPHASE;
	*(volatile uint32_t *)CSR_DDRPHY_WRPHASE_ADDR = SDRAM_PHY_WRPHASE;
	*(volatile uint32_t *)CSR_SDRAM_DFII_CONTROL_ADDR = (DFII_CONTROL_CKE|DFII_CONTROL_ODT|DFII_CONTROL_RESET_N);
	*(volatile uint32_t *)CSR_DDRPHY_RST_ADDR = 1;
	cdelay(1000);
	*(volatile uint32_t *)CSR_DDRPHY_RST_ADDR = 0;
	cdelay(1000);

    *(volatile uint32_t *)CSR_DDRCTRL_INIT_DONE_ADDR = 0;
	*(volatile uint32_t *)CSR_DDRCTRL_INIT_ERROR_ADDR = 0;

	/* Release reset */
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_CONTROL_ADDR = (DFII_CONTROL_ODT|DFII_CONTROL_RESET_N);
	cdelay(50000);

	/* Bring CKE high */
    *(volatile uint32_t *)CSR_SDRAM_DFII_PI0_ADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_CONTROL_ADDR = (DFII_CONTROL_CKE|DFII_CONTROL_ODT|DFII_CONTROL_RESET_N);
	cdelay(10000);

	/* Load Mode Register 2, CWL=5 */
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_ADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 2;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ADDR = (DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ISSUE_ADDR = 1;

	/* Load Mode Register 3 */
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_ADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 3;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ADDR = (DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ISSUE_ADDR = 1;

	/* Load Mode Register 1 */
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_ADDRESS_ADDR = 0x6;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 1;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ADDR = (DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ISSUE_ADDR = 1;

	/* Load Mode Register 0, CL=7, BL=8 */
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_ADDRESS_ADDR = 0x930;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ADDR = (DFII_COMMAND_RAS|DFII_COMMAND_CAS|DFII_COMMAND_WE|DFII_COMMAND_CS);
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ISSUE_ADDR = 1;
	cdelay(200);

	/* ZQ Calibration */
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_ADDRESS_ADDR = 0x400;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_BADDRESS_ADDR = 0;
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ADDR = (DFII_COMMAND_WE|DFII_COMMAND_CS);
	*(volatile uint32_t *)CSR_SDRAM_DFII_PI0_COMMAND_ISSUE_ADDR = 1;
	cdelay(200);

	sdram_read_leveling();

	*(volatile uint32_t *)CSR_SDRAM_DFII_CONTROL_ADDR = DFII_CONTROL_SEL;
	*(volatile uint32_t *)CSR_DDRCTRL_INIT_DONE_ADDR = 1;
	return 1;
}

-----------------------------------------------------------------------------
--
-- Linear Feedback Shift Register wrapper with TAP generation
--
-- This will generate PRN with maximum cycle length, i.e. for
-- a given DEPTH the cycle will be as close to 2^DEPTH as possible.
--
-----------------------------------------------------------------------------
-- Author : Kai Poggensee
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lfsr_polytable.all;


entity LFSR is
	generic(
		DEPTH				: positive range 2 to 168;
		RESET_VECTOR		: std_logic_vector(DEPTH-1 downto 0)
							:= (others => '1')
	);
	port(
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		STATUS_o			: out std_logic_vector(DEPTH-1 downto 0);
		Q_o					: out std_ulogic

	);
end entity;


architecture STRUCT of LFSR is

TODO: add this into an array of struct to look up after user request

2 2
3 3,2
4 4,3
5 5,3
6 6,5
7 7,6
8 8,6,5,4
9 9,5
10 10,7
11 11,9
12 12,6,4,1
13 13,4,3,1
14 14,5,3,1
15 15,14
16 16,15,13,4
17 17,14
18 18,11
19 19,6,2,1
20 20,17
21 21,19
22 22,21
23 23,18
24 24,23,22,17
25 25,22
26 26,6,2,1
27 27,5,2,1
28 28,25
29 29,27
30 30,6,4,1
31 31,28
32 32,22,2,1
33 33,20
34 34,27,2,1
35 35,33
36 36,25
37 37,5,4,3,2,1
38 38,6,5,1
39 39,35
40 40,38,21,19
41 41,38
42 42,41,20,19
43 43,42,38,37
44 44,43,18,17
45 45,44,42,41
46 46,45,26,25
47 47,42
48 48,47,21,20
49 49,40
50 50,49,24,23
51 51,50,36,35
52 52,49
53 53,52,38,37
54 54,53,18,17
55 55,31
56 56,55,35,34
57 57,50
58 58,39
59 59,58,38,37
60 60,59
61 61,60,46,45
62 62,61,6,5
63 63,62 105
64 64,63,61,60
65 65,47
66 66,65,57,56
67 67,66,58,57
68 68,59 110
69 69,67,42,40
70 70,69,55,54
71 71,65
72 72,66,25,19
73 73,48
74 74,73,59,58
75 75,74,65,64
76 76,75,41,40
77 77,76,47,46
78 78,77,59,58
79 79,70
80 80,79,43,42
81 81,77
82 82,79,47,44
83 83,82,38,37
84 84,71
85 85,84,58,57
86 86,85,74,73
87 87,74
88 88,87,17,16
89 89,51
90 90,89,72,71
91 91,90,8,7
92 92,91,80,79
93 93,91
94 94,73
95 95,84
96 96,94,49,47
97 97,91
98 98,87
99 99,97,54,52
100 100,63
101 101,100,95,94
102 102,101,36,35
103 103,94
104 104,103,94,93
105,89
106 106,91
107 107,105,44,42
108 108,77
109 109,108,103,102
110,109,98,97
111 111,101
112 112,110,69,67
113 113,104
114 114,113,33,32
115 115,114,101,100
116 116,115,46,45
117 117,115,99,97
118 118,85
119 119,111
120 120,113,9,2
121 121,103
122 122,121,63,62
123 123,121
124 124,87
125 125,124,18,17
126 126,125,90,89
127 127,126
128 128,126,101,99
129 129,124
130 130,127
131 131,130,84,83
132 132,103
133 133,132,82,81
134 134,77
135 135,124
136 136,135,11,10
137 137,116
138 138,137,131,130
139 139,136,134,131
140 140,111
141 141,140,110,109
142 142,121
143 143,142,123,122
144 144,143,75,74
145 145,93
146 146,145,87,86
147 147,146,110,109
148 148,121
149 149,148,40,39
150 150,97
151 151,148
152 152,151,87,86
153 153,152
154 154,152,27,25
155 155,154,124,123
156 156,155,41,40
157 157,156,131,130
158 158,157,132,131
159 159,128
160 160,159,142,141
161 161,143
162 162,161,75,74
163 163,162,104,103
164 164,163,151,150
165 165,164,135,134
166 166,165,128,127
167 167,161
168 168,166,153,151

	component LFSR_GALOIS is
	generic(
		DEPTH				: positive;
		TAPS				: std_logic_vector(DEPTH-1 downto 0);
		RESET_VECTOR		: std_logic_vector(DEPTH-1 downto 0)
							:= (others => '1')
	);
	port(
		nRST_i				: in std_ulogic;
		CLK_i				: in std_ulogic;
		CLK_EN_i			: in std_ulogic;

		STATUS_o			: out std_logic_vector(DEPTH-1 downto 0);
		Q_o					: out std_ulogic

	);
	end entity;


begin

	--
	-- sanity checks
	--

	assert ( (DEPTH >= 2) and (DEPTH <= 168) )
	report "Error: Only depth from 2 to 168 implemented!"
		severity error;

	assert ( RESET_VECTOR /= (RESET_VECTOR'range => '0') )
	report "Error: Reset Vector cannot be all zeros!"
		severity error;


	--
	-- instantiation
	--

	LFSR_GALOIS_INST: LFSR_GALOIS
	generic map (
		DEPTH				=> DEPTH,
		TAPS				=> TAPS,
		RESET_VECTOR		=> RESET_VECTOR
	)
	port map (
		nRST_i				=> nRST_i,
		CLK_i				=> CLK_i,
		CLK_EN_i			=> CLK_EN_i,

		STATUS_o			=> STATUS_o,
		Q_o					=> Q_o,

	);

end architecture;

function G = LPF_Gaussian(Fc,Fs)
% LPF_GAUSSIAN Returns a Gaussian LPF.
% FIR Window Lowpass filter designed using the FIR1 function.

% All frequency values are in Hz.
% Fs: Sampling Frequency
% Fc: Cutoff Frequency
% N: Order

Nmin = ceil(0.1*Fs); % dur of filter is at least 100 msec
N1 = ceil(Fs/Fc);
Fnyq = Fs/2; % Nyquist frequency
N2 = ceil(Fs/(Fnyq-Fc));
N = max([N1,N2,Nmin]);
if mod(N,2)
    N = N+1;
end

flag  = 'scale';  % Sampling Flag
Alpha = 4;        % Window Parameter
% Create the window vector for the design algorithm.
win = gausswin(N+1, Alpha);

% Calculate the coefficients using the FIR1 function.
b  = fir1(N, Fc/(Fs/2), 'low', win, flag);
Hd = dfilt.dffir(b);

G = Hd.Numerator;
G = G/sum(G);

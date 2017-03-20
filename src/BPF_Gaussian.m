function G = BPF_Gaussian(Fc1,Fc2,Fs)
%BPF_GAUSSIAN Returns a Gaussian BPF.
% FIR Window Bandpass filter designed using the FIR1 function.

% All frequency values are in Hz.
% Fs: Sampling Frequency
% N: Order
% Fc1: First Cutoff Frequency
% Fc2: Second Cutoff Frequency

Nmin = ceil(0.1*Fs); % dur of filter is at least 100 msec
N11 = ceil(0.3*Fs/Fc1);
N12 = ceil(0.3*Fs/Fc2);
Fnyq = Fs/2; % Nyquist frequency
N21 = ceil(0.3*Fs/(Fnyq-Fc1));
N22 = ceil(0.3*Fs/(Fnyq-Fc2));
N = max([N11,N12,N21,N22,Nmin]);
if mod(N,2)
    N = N+1;
end

flag  = 'scale';  % Sampling Flag
Alpha = 0.1;      % Window Parameter
% Create the window vector for the design algorithm.
win = gausswin(N+1, Alpha);

% Calculate the coefficients using the FIR1 function.
b  = fir1(N, [Fc1 Fc2]/(Fs/2), 'bandpass', win, flag);
Hd = dfilt.dffir(b);

G = Hd.Numerator;

clc;
clear;
close all;
num_trials = 50;     % number of Monte Carlo runs
N = 5e5;                  % number of bits
data = round(rand(1,N));  % random binary data
bpsk_signal = 2*data - 1;
snr_db = 0:2:20;
ber_awgn = zeros(size(snr_db));

for i = 1:length(snr_db)

    snr_linear = 10^(snr_db(i)/10);
    noise_std = sqrt(1/(2*snr_linear));

    error_sum = 0;

    for trial = 1:num_trials

        data = round(rand(1,N));
        bpsk_signal = 2*data - 1;

        noise = noise_std * randn(1,N);

        rx = bpsk_signal + noise;

        detected = rx > 0;

        error_sum = error_sum + sum(detected ~= data);

    end

    ber_awgn(i) = error_sum/(N*num_trials);

end

ber_rayleigh = zeros(size(snr_db));

for i = 1:length(snr_db)

    snr = snr_db(i);

    snr_linear = 10^(snr/10);

    h = (randn(1,N) + 1i*randn(1,N))/sqrt(2);

    faded = h .* bpsk_signal;

    noise_std = sqrt(1/(2*snr_linear));

    noise = noise_std * (randn(1,N) + 1i*randn(1,N));

    rx = faded + noise;

    equalized = rx ./ h;

    detected = real(equalized) > 0;

    ber_rayleigh(i) = sum(detected ~= data)/N;

end

bits = round(rand(1,N));
ber_qpsk = zeros(size(snr_db));

for i = 1:length(snr_db)

    I = bits(1:2:end);
    Q = bits(2:2:end);

    qpsk_signal = (2*I-1) + 1i*(2*Q-1);
    qpsk_signal = qpsk_signal/sqrt(2);

    snr_linear = 10^(snr_db(i)/10);

    noise_std = sqrt(1/(2*snr_linear));

    noise = noise_std * (randn(size(qpsk_signal)) + 1i*randn(size(qpsk_signal)));

    rx = qpsk_signal + noise;

    I_hat = real(rx) > 0;
    Q_hat = imag(rx) > 0;

    detected = zeros(1,N);
    detected(1:2:end) = I_hat;
    detected(2:2:end) = Q_hat;

    ber_qpsk(i) = sum(bits ~= detected)/N;

end

ber_16qam = zeros(size(snr_db));

bits_qam = round(rand(1,N));

for i = 1:length(snr_db)

    snr_linear = 10^(snr_db(i)/10);

    noise_std = sqrt(1/(2*snr_linear));

    % group bits into symbols
    bits = reshape(bits_qam,4,[]);

    I = 2*bits(1,:) + bits(2,:);
    Q = 2*bits(3,:) + bits(4,:);

    % map to constellation
    I = 2*I - 3;
    Q = 2*Q - 3;

    qam_signal = I + 1i*Q;

    qam_signal = qam_signal / sqrt(10);

    noise = noise_std*(randn(size(qam_signal)) + 1i*randn(size(qam_signal)));

    rx = qam_signal + noise;

    % detection
    I_hat = round((real(rx)*sqrt(10)+3)/2);
    Q_hat = round((imag(rx)*sqrt(10)+3)/2);

    I_hat = min(max(I_hat,0),3);
    Q_hat = min(max(Q_hat,0),3);

    bits_hat = zeros(size(bits));
    bits_hat(1,:) = floor(I_hat/2);
    bits_hat(2,:) = mod(I_hat,2);
    bits_hat(3,:) = floor(Q_hat/2);
    bits_hat(4,:) = mod(Q_hat,2);

    detected = reshape(bits_hat,1,[]);

    ber_16qam(i) = sum(detected ~= bits_qam)/length(bits_qam);

end

snr_linear = 10.^(snr_db/10);
ber_theoretical = max(0.5 * erfc(sqrt(snr_linear)),1e-6);

figure

semilogy(snr_db, ber_awgn,'-o','LineWidth',2)
hold on

semilogy(snr_db, ber_rayleigh,'-s','LineWidth',2)

semilogy(snr_db, ber_qpsk,'-*','LineWidth',2)

semilogy(snr_db, ber_theoretical,'--','LineWidth',2)
semilogy(snr_db, ber_16qam,'-d','LineWidth',2)

grid on
xlabel('SNR (dB)')
ylabel('Bit Error Rate')

legend('BPSK AWGN','BPSK Rayleigh','QPSK AWGN','16QAM AWGN','BPSK Theoretical')

title('BER Performance of Digital Modulation Schemes')

saveas(gcf,'../figures/ber_plot.png')
save('../results/ber_data.mat','snr_db','ber_awgn','ber_rayleigh','ber_qpsk')
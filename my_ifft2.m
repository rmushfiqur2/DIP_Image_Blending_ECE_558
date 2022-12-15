function f = my_ifft2(F)
    % input F 2D FFT of size (M,N)
    M = size(F,1);
    N = size(F,2);
    % output f is ifft2 of f of same size

    f = conj(my_fft2(conj(F)))/(M*N);
end
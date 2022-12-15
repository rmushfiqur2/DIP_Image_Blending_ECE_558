function F = my_fft2(f)
    % input f 2D image of size (M,N)
    M = size(f,1);
    N = size(f,2);
    % output F is fft2 of f of same size
    F = zeros(M,N);

    for i=1:N % for each column
        F(:,i) = fft(f(:,i)); % complexity M*log(M)
    end
    for i=1:M % for each row
        F(i,:) = fft(F(i,:)); % complexity M*log(M)
    end
end
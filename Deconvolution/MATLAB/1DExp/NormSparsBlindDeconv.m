function [f_est, h_est] = NormSparsBlindDeconv(g, f_size, h_size, iter, lambda_f, lambda_h, psi_h, M, N, t, iter_irls, iter_pcg, iter_lucy)
    y = conv(g, [1 -1], "same");
    y = y./sum(y);
    x = y((end-f_size)/2+1:(end+f_size)/2);
    %x = ones(1, f_size);
    k = ones(1, h_size);
    for i=1:iter        
        x = x_update(k, x, lambda_f, M, N, t, y);
        k = k_update(x, k, y, lambda_h, psi_h, iter_irls, iter_pcg);
    end
    h_est = k;
    f_est = deconvlucy(g, k, iter_lucy);
end

function out = x_update(k, x, lambda, M, N, t, y)
    for j=1:M
        lambda_prime = lambda*norm(x);
        x = ista(k, lambda_prime, x, t, N, y);
    end
    out = x./sum(x);
end

function out = ista(k, lambda, x, t, N, y)
    K = convmtx(k', length(x));
    for j=1:N
        v = x'-t*K'*(K*x' - y');
        x = (max(abs(v) - t*lambda, 0).*sign(v))';
    end
    out = x;
end

function out = k_update(x, k, y, lambda, psi, iter_irls, iter_pcg)
    for i=1:iter_irls
        W = zeros(length(k));
        for j=1:length(k)
            W(j, j) = 1/max(0.01, abs(k(j)));
        end
        X = convmtx(x', length(k));
        A = 2*lambda*(X'*X) + psi*W;
        b = 2*lambda*X'*y';
        k = (pcg(A, b, 1e-6, iter_pcg))';
    end
    k(k<0) = 0;
    out = k./sum(k);
end

% clear all
% close all
% 
% x = linspace(-1, 1, 1000);
% mu = 0;
% sigma = 0.01;
% h_prep1 = normpdf(x, mu, sigma)/normpdf(0, mu, sigma);
% delta_num = 8;
% h_prep2 = zeros(1, 1000);
% h_prep2(1+length(h_prep2)/delta_num/2:length(h_prep2)/delta_num:end) = 1;
% h = conv(h_prep1, h_prep2);
% 
% 
% delta_num = 2;
% f = zeros(1, 1000);
% f(1+length(f)/delta_num/2:length(f)/delta_num:end) = 1;
% subplot(1, 2, 1)
% stem(f);
% title('Original signal')
% subplot(1, 2, 2);
% stem(h);
% title('Impulse response')
% 
% figure;
% g = conv(h, f);
% g = g/sum(g);
% stem(g);
% title('Convolved signal')
% 
% figure;
% [f_est, h_est] = norm_spars_bd(g, length(f), length(h), 50, 20, 20, 0.5, 2, 2, 0.001, 1, 20, 10);
% subplot(1, 2, 1)
% stem(f_est);
% subplot(1, 2, 2);
% stem(h_est);
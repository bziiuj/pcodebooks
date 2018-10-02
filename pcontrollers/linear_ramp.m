function [y] = linear_ramp(b_p_data, params)

min_radius = params(1);
max_radius = params(2);

x = b_p_data(:, 2);

y = zeros(length(x), 1);
for i = 1:length(x)
    if x(i) <= min_radius
        y(i) = 0;
    elseif x(i) >= max_radius
        y(i) = 1;
    else
        y(i) = (x(i) - min_radius) / (max_radius - min_radius);
    end
end
end


module Utils

include("./consts.jl")
include("./equas.jl")

# module
using .Consts: MASS
using .Equas: P, Q, m, zeta_inf, gamma, alpha, b


# library
using Elliptic
using Elliptic.Jacobi
using Plots

using PyCall
mp = pyimport("mpmath")


function search_zero(f, min, max)
    """
    関数の零点を求める
    """
    tmp_max = 1e10
    rtv = 0
    for i in min:0.025:max
        if f(i) < tmp_max
            tmp_max = f(i)
            rtv = i
        end
    end
    return rtv
end


function func_0(b, r, phi)
    p_val = P(b)
    q_val = Q(p_val)
    zeta_inf_val = zeta_inf(p_val)
    m_val = m(p_val)

    ellipf = @pycall mp.ellipf(zeta_inf_val, m_val)::Complex{Float64}
    inner = gamma(phi) * sqrt(q_val / p_val) / 2 + ellipf
    ellipfun = @pycall mp.ellipfun("sn", inner, m_val)::Complex{Float64}

    term1 = (q_val - p_val + 6 * MASS) / (4 * MASS * p_val)
    term2 = (q_val - p_val + 2 * MASS) / (4 * MASS * p_val)
    return abs(term1 * ellipfun ^ 2 - term2 - 1 / r)
    # return real(term1 * ellipfun ^ 2 - term2 - 1 / r)
end


function func_n(p_val, r, phi, n)
    q_val = Q(p_val)
    zeta_inf_val = zeta_inf(p_val)
    m_val = m(p_val)

    ellipf = F(zeta_inf_val, m_val)
    inner = 2 * K(m_val) - ellipf - (1 / 2) * sqrt(q_val / p_val) * (2 * pi * n - gamma(phi))
    ellipfun = sn(inner, m_val)

    term1 = (q_val - p_val + 6 * MASS) / (4 * MASS * p_val)
    term2 = (q_val - p_val + 2 * MASS) / (4 * MASS * p_val)
    return abs(term1 * ellipfun ^ 2 - term2 - 1 / r)
end


function calc_disk_image(r, phi, n=0)
    """
    降着円盤上の粒子に対応した像の位置を計算する
    """
    alpha_val = alpha(phi)
    if n == 0
        f = b -> func_0(b, r, phi)
        b_val = search_zero(f, 0.01 * MASS, 40 * MASS)
        # b_val = binary_search_zero(f, 0.01 * MASS, 40 * MASS)
    else
        f = p -> func_n(p, r, phi, n)
        p_val = search_zero(f, 3 * MASS, 40 * MASS)
        b_val = b(p_val)
    end
    return b_val, alpha_val
end


function plot_disk_image(plt, r_list, theta_list, color, reverse=false)
    """
    極座標系のデータを直交座標系に変換して描画する
    """
    y_sign = reverse ? 1 : -1
    x = [-r_list[1] * sin(theta_list[1]), r_list[1] * sin(theta_list[1])]
    y = [y_sign * r_list[1] * cos(theta_list[1]), y_sign * r_list[1] * cos(theta_list[1])]
    plot!(plt, x, y, color=color)

    # 左右対称の描画
    for sign in [-1, 1]  # 符号を反転して左右対称に
        y_sign = reverse ? 1 : -1
        x = [sign * r * sin(theta) for (r, theta) in zip(r_list, theta_list)]
        y = [y_sign * r * cos(theta) for (r, theta) in zip(r_list, theta_list)]
        plot!(plt, x, y, color=color)
    end

    y_sign = reverse ? 1 : -1
    x = [-r_list[end] * sin(theta_list[end]), r_list[end] * sin(theta_list[end])]
    y = [y_sign * r_list[end] * cos(theta_list[end]), y_sign * r_list[end] * cos(theta_list[end])]
    plot!(plt, x, y, color=color)

    return plt
end


function write_text(path, b_list, alpha_list)
    """
    テキストファイルに書き込む
    """
    open(path, "w") do file
        println(file, "b,alpha")
        for (b, alpha) in zip(b_list, alpha_list)
            println(file, join([b, alpha], ","))
        end
    end
end


function read_text(path)
    """
    テキストファイルを読み込む
    """
    lines = readlines(path)
    split(strip(lines[1]), ",") # delete header
    b_list = []
    alpha_list = []
    for line in lines[2:end]
        push!(b_list, parse(Float64, split(strip(line), ",")[1]))
        push!(alpha_list, parse(Float64, split(strip(line), ",")[2]))
    end
    return b_list, alpha_list
end

export plot_disk_image, read_text, write_text, calc_disk_image

end
using TySignalProcessing
using TyPlot
using TyMath
using TyCommunication
using TyBase

#利用函数生成随机数
rng = MT19937ar(1234)
y = randn(rng, 8000, 1)

initcodebook = collect(-1:0.005:2)
# 优化参数
predictor, codebook, partition = dpcmopt(vec(y), 1, initcodebook)
encodex, quants= dpcmenco(vec(y), codebook, partition, vec(predictor))
# 十进制转二进制
i_b = int2bit(encodex, 9) #2进制输入信号

# 生成网格结构
trellis1 = poly2trellis([5 4], [23 35 0; 0 5 13])
K = log2(trellis1.numInputSymbols)  #输入信息的比特数
N = log2(trellis1.numOutputSymbols) #输出信息的比特数
numReg = log2(trellis1.numStates)   #寄存器个数
#卷积编码
codedout, = convenc(i_b, trellis1) #卷积编码后的2进制输入信号

#QPSK调制
QPSKmod = comm_QPSKModulator(; BitInput=true)
qpskData = step(QPSKmod, codedout)

#AWGN
hAWGN = comm_AWGNChannel(;     #信道模型·
    NoiseMethod="Signal to noise ratio (SNR)",
    SNR=20,
    SignalPower=0.89,
    RandomStream="mt19937ar with seed",
    Seed=1234,
)
noisySignal1 = step(hAWGN, qpskData)

#瑞利衰落信道
rayleighchan = comm_RayleighChannel(;
SampleRate=7.68e6,
PathDelays=[0 1.5e-4], #离散路径延迟，当将 PathDelays 设置为标量时，道是频率平坦的，当将 PathDelays 设置为向量时，信道是频率选择性的
AveragePathGains=[1 2], #离散路径的平均增益
NormalizePathGains=true, # 归一化平均路径增益，当等于true，对衰落过程归一化处理，使得路径增益的总功率（随时间平均）为 0 dB；false - 路径增益的总功率未归一化处理。
MaximumDopplerShift=30,  #所有路径的最大多普勒频移，为 0 时，信道在整个输入中保持静态
DopplerSpectrum=[doppler("Gaussian", 0.6), doppler("Flat")], #所有信道路径的多普勒频谱形状
RandomStream="mt19937ar with seed",
Seed=1234,
PathGainsOutputPort=true, #输出信道路径增益
)
noisySignal2, pathGains1 = step(rayleighchan, qpskData) #瑞利

#QPSK解调
QPSKdmod = comm_QPSKDemodulator(; BitOutput=true)
qpskdData1 = step(QPSKdmod, noisySignal1)
#瑞利
QPSKdmod = comm_QPSKDemodulator(; BitOutput=true)
qpskdData2 = step(QPSKdmod, noisySignal2)

#星座图绘制
figure(1)
sgtitle("解调后的星座图")
scatterplot(qpskdData1)
grid("on")
title("QPSKDe")
tightlayout()
#星座图绘制
figure(2)
sgtitle("理想星座图")
scatterplot(qpskData)
grid("on")
title("QPSK")
tightlayout()
figure(3)
subplot(1, 2, 1)
sgtitle("不同信道情况的星座图")
scatterplot(noisySignal1)
grid("on")
title("QPSK-AWGN")
subplot(1, 2, 2)
scatterplot(noisySignal2)
grid("on")
title("QPSK-Rayleigh")
tightlayout()
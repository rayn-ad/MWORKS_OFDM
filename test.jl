using TySignalProcessing
using TyPlot
using TyMath
using TyCommunication
using TyBase

using TyCommunication
using TyMath
using TyPlot
rng = MT19937ar(1234)
hQAMMod = comm_GeneralQAMModulator()
hQAMMod.Constellation =
 [-1-1im,  -1+1im, 
  1-1im,    1+1im,  ]
data = randi(rng, [0 3], 100, 1)
modData = step(hQAMMod, data)
scatterplot(modData)
xlim([-1.1 1.1])
ylim([-1.1 1.1])




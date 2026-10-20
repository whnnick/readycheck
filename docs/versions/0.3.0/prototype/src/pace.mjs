function samples(remaining, rate, count=13) {
 return Array.from({length:count},(_,i)=>({minute:(i-count+1)*5,remaining:remaining+rate*(count-1-i)/12}));
}
export const scenarios={
 risk:{remaining:34,resetMinutes:120,points:samples(34,24)},
 safe:{remaining:54,resetMinutes:120,points:samples(54,12)},
 short:{remaining:68,resetMinutes:240,points:samples(68,12,3)},
 stale:{remaining:34,resetMinutes:120,points:samples(34,24),stale:true},
 reset:{remaining:98,resetMinutes:298,points:samples(98,6,2)},
 volatile:{remaining:34,resetMinutes:120,points:Array.from({length:13},(_,i)=>({minute:(i-12)*5,remaining:34+(i<6?(6-i)*0.5+18:(12-i)*3)}))},
 idle:{remaining:72,resetMinutes:120,points:samples(72,0)}
};
export function evaluatePace(data, threshold) {
 const empty={kind:'short',rate:null,minutesToThreshold:null,remainingAtReset:null,observedMinutes:0};
 if(data.stale)return {...empty,kind:'stale'};
 const deltas=data.points.slice(1).map((p,i)=>({minutes:p.minute-data.points[i].minute,drop:data.points[i].remaining-p.remaining}));
 if(deltas.some(p=>p.minutes<=0||p.minutes>10||p.drop<0))return empty;
 const observedMinutes=deltas.reduce((s,p)=>s+p.minutes,0);
 if(observedMinutes<30||data.points.length<7)return {...empty,observedMinutes};
 const rate=deltas.reduce((s,p)=>s+p.drop,0)/observedMinutes*60;
 const base={...empty,observedMinutes,rate};
 if(data.remaining<=threshold)return {...base,kind:'low'};
 if(rate===0)return {...base,kind:'idle'};
 const half=Math.floor(deltas.length/2);
 const avg=xs=>xs.reduce((s,p)=>s+p.drop,0)/xs.reduce((s,p)=>s+p.minutes,0);
 const a=avg(deltas.slice(0,half)),b=avg(deltas.slice(half));
 if(Math.max(a,b)>Math.max(Math.min(a,b)*3,0.1))return {...empty,kind:'volatile',observedMinutes};
 const minutesToThreshold=(data.remaining-threshold)/rate*60;
 return {...base,kind:minutesToThreshold<=data.resetMinutes?'risk':'safe',minutesToThreshold,remainingAtReset:Math.max(0,data.remaining-rate*data.resetMinutes/60)};
}

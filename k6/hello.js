// k6 run --vus 1000 --duration 30s hello.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export default function () {
  const res = http.get('http://172.31.23.222/100k.img');
  check(res, { 'status was 200': (r) => r.status == 200 });
}

// export default function () {
//   var url = 'http://220.160.54.46:81/search';
//   var payload = JSON.stringify({
//     logname: 'aaa',
//     pwd: '0cc175b9c0f1b6a831c399e269772661',
//     ksh: '12345677',
//     check: 'dddd',
//   });

//   var params = {
//     headers: {
//       'Content-Type': 'application/x-www-form-urlencoded',
//     },
//   };

//   const res = http.post(url, payload, params);
//   check(res, { 'status was 200': (r) => r.status == 200 });
// }

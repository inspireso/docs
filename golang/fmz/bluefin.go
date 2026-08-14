/*
GOOS=linux GOARCH=amd64 go build -ldflags '-s -w -extldflags -static' rest_bitgo.go
*/
package main

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

func toFloat(s interface{}) float64 {
    var ret float64
    switch v := s.(type) {
    case float64:
        ret = v
    case float32:
        ret = float64(v)
    case int64:
        ret = float64(v)
    case int:
        ret = float64(v)
    case int32:
        ret = float64(v)
    case string:
        ret, _ = strconv.ParseFloat(strings.TrimSpace(v), 64)
    }
    return ret
}

func float2str(i float64) string {
    return strconv.FormatFloat(i, 'f', -1, 64)
}

func toInt64(s interface{}) int64 {
    var ret int64
    switch v := s.(type) {
    case int:
        ret = int64(v)
    case float64:
        ret = int64(v)
    case bool:
        if v {
            ret = 1
        } else {
            ret = 0
        }
    case int64:
        ret = v
    case string:
        ret, _ = strconv.ParseInt(strings.TrimSpace(v), 10, 64)
    }
    return ret
}

func toString(s interface{}) string {
    var ret string
    switch v := s.(type) {
    case string:
        ret = v
    case int64:
        ret = strconv.FormatInt(v, 10)
    case float64:
        ret = strconv.FormatFloat(v, 'f', -1, 64)
    case bool:
        ret = strconv.FormatBool(v)
    default:
        ret = fmt.Sprintf("%v", s)
    }
    return ret
}

type Json struct {
    data interface{}
}

func NewJson(body []byte) (*Json, error) {
    j := new(Json)
    err := j.UnmarshalJSON(body)
    if err != nil {
        return nil, err
    }
    return j, nil
}

func (j *Json) UnmarshalJSON(p []byte) error {
    return json.Unmarshal(p, &j.data)
}

func (j *Json) Get(key string) *Json {
    m, err := j.Map()
    if err == nil {
        if val, ok := m[key]; ok {
            return &Json{val}
        }
    }
    return &Json{nil}
}

func (j *Json) CheckGet(key string) (*Json, bool) {
    m, err := j.Map()
    if err == nil {
        if val, ok := m[key]; ok {
            return &Json{val}, true
        }
    }
    return nil, false
}

func (j *Json) Map() (map[string]interface{}, error) {
    if m, ok := (j.data).(map[string]interface{}); ok {
        return m, nil
    }
    return nil, errors.New("type assertion to map[string]interface{} failed")
}

func (j *Json) Array() ([]interface{}, error) {
    if a, ok := (j.data).([]interface{}); ok {
        return a, nil
    }
    return nil, errors.New("type assertion to []interface{} failed")
}

func (j *Json) Bool() (bool, error) {
    if s, ok := (j.data).(bool); ok {
        return s, nil
    }
    return false, errors.New("type assertion to bool failed")
}

func (j *Json) String() (string, error) {
    if s, ok := (j.data).(string); ok {
        return s, nil
    }
    return "", errors.New("type assertion to string failed")
}

func (j *Json) Bytes() ([]byte, error) {
    if s, ok := (j.data).(string); ok {
        return []byte(s), nil
    }
    return nil, errors.New("type assertion to []byte failed")
}

func (j *Json) Int() (int, error) {
    if f, ok := (j.data).(float64); ok {
        return int(f), nil
    }

    return -1, errors.New("type assertion to float64 failed")
}

func (j *Json) MustArray(args ...[]interface{}) []interface{} {
    var def []interface{}

    switch len(args) {
    case 0:
    case 1:
        def = args[0]
    default:
        log.Panicf("MustArray() received too many arguments %d", len(args))
    }

    a, err := j.Array()
    if err == nil {
        return a
    }

    return def
}

func (j *Json) MustMap(args ...map[string]interface{}) map[string]interface{} {
    var def map[string]interface{}

    switch len(args) {
    case 0:
    case 1:
        def = args[0]
    default:
        log.Panicf("MustMap() received too many arguments %d", len(args))
    }

    a, err := j.Map()
    if err == nil {
        return a
    }

    return def
}

func (j *Json) MustString(args ...string) string {
    var def string

    switch len(args) {
    case 0:
    case 1:
        def = args[0]
    default:
        log.Panicf("MustString() received too many arguments %d", len(args))
    }

    s, err := j.String()
    if err == nil {
        return s
    }

    return def
}

func (j *Json) MustInt64() int64 {
    var ret int64
    var err error
    switch v := j.data.(type) {
    case int:
        ret = int64(v)
    case int64:
        ret = v
    case float64:
        ret = int64(v)
    case string:
        if ret, err = strconv.ParseInt(v, 10, 64); err != nil {
            panic(err)
        }
    default:
        ret = 0
        //panic("type assertion to int64 failed")
    }
    return ret
}

func (j *Json) MustFloat64() float64 {
    var ret float64
    var err error
    switch v := j.data.(type) {
    case int:
        ret = float64(v)
    case int64:
        ret = float64(v)
    case float64:
        ret = v
    case string:
        v = strings.Replace(v, ",", "", -1)
        if ret, err = strconv.ParseFloat(v, 64); err != nil {
            panic(err)
        }
    default:
        ret = 0
        //panic("type assertion to float64 failed")
    }
    return ret
}

type iBitgo struct {
    accessKey     string
    secretKey     string
    currency      string
    opCurrency    string
    baseCurrency  string
    secret        string
    secretExpires int64
    apiBase       string
    step          int64
    newRate       float64
    timeout       time.Duration
    timeLocation  *time.Location
}

type MapSorter []Item

type Item struct {
    Key string
    Val string
}

func NewMapSorter(m map[string]string) MapSorter {
    ms := make(MapSorter, 0, len(m))

    for k, v := range m {
        if strings.HasPrefix(k, "!") {
            k = strings.Replace(k, "!", "", -1)
        }
        ms = append(ms, Item{k, v})
    }

    return ms
}

func (ms MapSorter) Len() int {
    return len(ms)
}

func (ms MapSorter) Less(i, j int) bool {
    //return ms[i].Val < ms[j].Val // 按值排序
    return ms[i].Key < ms[j].Key // 按键排序
}

func (ms MapSorter) Swap(i, j int) {
    ms[i], ms[j] = ms[j], ms[i]
}

func encodeParams(params map[string]string, escape bool) string {
    ms := NewMapSorter(params)
    sort.Sort(ms)

    v := url.Values{}
    for _, item := range ms {
        v.Add(item.Key, item.Val)
    }
    if escape {
        return v.Encode()
    }
    var buf bytes.Buffer
    keys := make([]string, 0, len(v))
    for k := range v {
        keys = append(keys, k)
    }
    sort.Strings(keys)
    for _, k := range keys {
        vs := v[k]
        prefix := k + "="
        for _, v := range vs {
            if buf.Len() > 0 {
                buf.WriteByte('&')
            }
            buf.WriteString(prefix)
            buf.WriteString(v)
        }
    }
    return buf.String()
}

func newBitgo(accessKey, secretKey string) *iBitgo {
    s := new(iBitgo)
    s.accessKey = accessKey
    s.secretKey = secretKey
    s.apiBase = "https://www.bitgo.cn"
    s.timeout = 20 * time.Second
    s.timeLocation = time.FixedZone("Asia/Shanghai", 8*60*60)

    return s
}

func (p *iBitgo) apiCall(method string) (*Json, error) {
    req, err := http.NewRequest("POST", fmt.Sprintf("%s/appApi.html?%s", p.apiBase, method), nil)
    if err != nil {
        return nil, err
    }
    req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    b, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    return NewJson(b)
}

func (p *iBitgo) GetTicker(symbol string) (ticker interface{}, err error) {
    var js *Json
    js, err = p.apiCall("action=market&symbol=" + symbol)
    if err != nil {
        return
    }
    dic := js.Get("data")
    ticker = map[string]interface{}{
        "time": js.Get("time").MustInt64(),
        "buy":  dic.Get("buy").MustFloat64(),
        "sell": dic.Get("sell").MustFloat64(),
        "last": dic.Get("last").MustFloat64(),
        "high": dic.Get("high").MustFloat64(),
        "low":  dic.Get("low").MustFloat64(),
        "vol":  dic.Get("vol").MustFloat64(),
    }
    return
}

func (p *iBitgo) GetDepth(symbol string) (depth interface{}, err error) {
    var js *Json
    js, err = p.apiCall("action=depth&symbol=" + symbol)
    if err != nil {
        return
    }
    dic := js.Get("data")

    asks := [][2]float64{}
    bids := [][2]float64{}

    for _, pair := range dic.Get("asks").MustArray() {
        arr := pair.([]interface{})
        asks = append(asks, [2]float64{toFloat(arr[0]), toFloat(arr[1])})
    }

    for _, pair := range dic.Get("bids").MustArray() {
        arr := pair.([]interface{})
        bids = append(bids, [2]float64{toFloat(arr[0]), toFloat(arr[1])})
    }
    depth = map[string]interface{}{
        "time": js.Get("time").MustInt64(),
        "asks": asks,
        "bids": bids,
    }
    return
}

func (p *iBitgo) GetTrades(symbol string) (trades interface{}, err error) {
    var js *Json
    js, err = p.apiCall("action=trades&symbol=" + symbol)
    if err != nil {
        return
    }
    dic := js.Get("data")
    items := []map[string]interface{}{}
    for _, pair := range dic.MustArray() {
        item := map[string]interface{}{}
        arr := pair.(map[string]interface{})
        item["id"] = toInt64(arr["id"])
        item["price"] = toFloat(arr["price"])
        item["amount"] = toFloat(arr["amount"])
        // trade.Time = toInt64(arr["time"]) * 1000
        if toString(arr["en_type"]) == "bid" {
            item["type"] = "buy"
        } else {
            item["type"] = "sell"
        }
        items = append(items, item)
    }
    trades = items
    return
}

func (p *iBitgo) GetRecords(step int64, symbol string) (records interface{}, err error) {
    var js *Json
    js, err = p.apiCall(fmt.Sprintf("action=kline&symbol=%s&step=%d", symbol, step*60))
    if err != nil {
        return
    }
    items := []interface{}{}
    for _, pair := range js.Get("data").MustArray() {
        arr := pair.([]interface{})
        if len(arr) < 6 {
            err = errors.New("response format error")
            return
        }
        item := [6]interface{}{}
        item[0] = toInt64(arr[0])
        item[1] = toFloat(arr[1])
        item[2] = toFloat(arr[2])
        item[3] = toFloat(arr[3])
        item[4] = toFloat(arr[4])
        item[5] = toFloat(arr[5])

        items = append(items, item)
    }
    records = items
    return
}

func (p *iBitgo) tapiCall(method string, params map[string]string) (js *Json, err error) {
    if params == nil {
        params = map[string]string{}
    }
    params["api_key"] = p.accessKey
    h := md5.New()
    h.Write([]byte(encodeParams(params, false) + "&secret_key=" + p.secretKey))
    params["sign"] = strings.ToUpper(hex.EncodeToString(h.Sum(nil)))
    params["action"] = method
    qs := encodeParams(params, false)

    req, err := http.NewRequest("POST", fmt.Sprintf("%s/appApi.html?%s", p.apiBase, qs), nil)
    if err != nil {
        return nil, err
    }
    req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    b, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    js, err = NewJson(b)
    if js != nil {
        if code := js.Get("code").MustInt64(); code != 200 {
            s := js.Get("msg").MustString()
            if s == "" {
                s = fmt.Sprintf("%v", toString(js.data))
            }
            return nil, errors.New(s)
        }
    }
    return js, err
}

func (p *iBitgo) GetAccount(symbol string) (account interface{}, err error) {
    var js *Json
    js, err = p.tapiCall("userinfo", nil)
    if err != nil {
        return
    }
    mp := js.Get("data")
    assets := map[string]map[string]interface{}{}
    for k := range mp.MustMap() {
        dic := mp.Get(k)
        if k == "free" {
            for c := range dic.MustMap() {
                if _, ok := assets[c]; !ok {
                    assets[c] = map[string]interface{}{}
                }
                assets[c]["currency"] = c
                assets[c]["free"] = dic.Get(c).MustFloat64()
            }
        } else if k == "frozen" {
            for c := range dic.MustMap() {
                if _, ok := assets[c]; !ok {
                    assets[c] = map[string]interface{}{}
                }
                assets[c]["currency"] = c
                assets[c]["frozen"] = dic.Get(c).MustFloat64()
            }
        }
    }
    accounts := []map[string]interface{}{}
    for _, pair := range assets {
        accounts = append(accounts, pair)
    }

    account = accounts
    return
}

func (p *iBitgo) Trade(side string, price, amount float64, symbol string) (orderId interface{}, err error) {
    var js *Json
    js, err = p.tapiCall("trade", map[string]string{
        "symbol": symbol,
        "type":   side,
        "price":  float2str(price),
        "amount": float2str(amount),
    })
    if err != nil {
        return
    }
    orderId = map[string]int64{"id": js.Get("orderId").MustInt64()}
    return
}

func (p *iBitgo) GetOrders(symbol string) (orders interface{}, err error) {
    var js *Json
    js, err = p.tapiCall("entrust", map[string]string{"symbol": symbol})
    if err != nil {
        return
    }
    items := []map[string]interface{}{}
    for _, ele := range js.Get("data").MustArray() {
        mp := ele.(map[string]interface{})
        item := map[string]interface{}{}
        item["id"] = toInt64(mp["id"])
        item["amount"] = toFloat(mp["count"])
        if _, ok := mp["prize"]; ok {
            item["price"] = toFloat(mp["prize"])
        } else {
            item["price"] = toFloat(mp["price"])
        }
        item["deal_amount"] = toFloat(mp["success_count"])

        if toInt64(mp["type"]) == 0 {
            item["type"] = "buy"
        } else {
            item["type"] = "sell"
        }
        item["status"] = "open"
        items = append(items, item)
    }
    return items, nil
}

func (p *iBitgo) GetOrder(orderId int64, symbol string) (order interface{}, err error) {
    var js *Json
    js, err = p.tapiCall("order", map[string]string{"id": toString(orderId)})
    if err != nil {
        return
    }

    found := false
    item := map[string]interface{}{}
    for _, ele := range js.Get("data").MustArray() {
        mp := ele.(map[string]interface{})
        if toInt64(mp["id"]) != orderId {
            continue
        }
        item["id"] = toInt64(mp["id"])
        item["amount"] = toFloat(mp["count"])
        if _, ok := mp["prize"]; ok {
            item["price"] = toFloat(mp["prize"])
        } else {
            item["price"] = toFloat(mp["price"])
        }
        item["deal_amount"] = toFloat(mp["success_count"])

        if toInt64(mp["type"]) == 0 {
            item["type"] = "buy"
        } else {
            item["type"] = "sell"
        }
        switch toInt64(mp["status"]) {
        case 1, 2:
            item["status"] = "open"
        case 3:
            item["status"] = "closed"
        case 4:
            item["status"] = "cancelled"
        }
        found = true
        break
    }
    if !found {
        return nil, errors.New("order not found")
    }
    return item, nil
}

func (p *iBitgo) CancelOrder(orderId int64, symbol string) (ret bool, err error) {
    _, err = p.tapiCall("cancel_entrust", map[string]string{"id": strconv.FormatInt(orderId, 10)})
    if err != nil {
        return
    }
    ret = true
    return
}

type RpcRequest struct {        // 结构体里的字段首字母必须大写，否则无法正常解析，结构体有导出和未导出，大写字母开头为导出。
                                // 在Unmarshal的时候会  根据 json 匹配查找该结构体的tag， 所以此处需要修饰符
    AccessKey string            `json:"access_key"`
    SecretKey string            `json:"secret_key"`
    Nonce     int64             `json:"nonce"`
    Method    string            `json:"method"`
    Params    map[string]string `json:"params"`
}

func OnPost(w http.ResponseWriter, r *http.Request) {
    var ret interface{}
    defer func() {
        if e := recover(); e != nil {
            if ee, ok := e.(error); ok {
                e = ee.Error()
            }
            ret = map[string]string{"error": fmt.Sprintf("%v", e)}
        }
        b, _ := json.Marshal(ret)
        w.Write(b)
    }()

    b, err := ioutil.ReadAll(r.Body)
    if err != nil {
        panic(err)
    }
    var request RpcRequest
    err = json.Unmarshal(b, &request)
    if err != nil {
        panic(err)
    }
    e := newBitgo(request.AccessKey, request.SecretKey)
    symbol := request.Params["symbol"]
    if s := request.Params["access_key"]; len(s) > 0 {
        e.accessKey = s
    }
    if s := request.Params["secret_key"]; len(s) > 0 {
        e.secretKey = s
    }
    if symbolIdx, ok := map[string]int{
        "btc":  1,
        "ltc":  2,
        "etp":  3,
        "eth":  4,
        "etc":  5,
        "doge": 6,
        "bec":  7,
    }[strings.Replace(strings.ToLower(symbol), "_cny", "", -1)]; ok {
        symbol = toString(symbolIdx)
    }
    var data interface{}
    switch request.Method {
    case "ticker":
        data, err = e.GetTicker(symbol)
    case "depth":
        data, err = e.GetDepth(symbol)
    case "trades":
        data, err = e.GetTrades(symbol)
    case "records":
        data, err = e.GetRecords(toInt64(request.Params["period"]), symbol)
    case "accounts":
        data, err = e.GetAccount(symbol)
    case "trade":
        side := request.Params["type"]
        if side == "buy" {
            side = "0"
        } else {
            side = "1"
        }
        price := toFloat(request.Params["price"])
        amount := toFloat(request.Params["amount"])
        data, err = e.Trade(side, price, amount, symbol)
    case "orders":
        data, err = e.GetOrders(symbol)
    case "order":
        data, err = e.GetOrder(toInt64(request.Params["id"]), symbol)
    case "cancel":
        data, err = e.CancelOrder(toInt64(request.Params["id"]), symbol)
    default:
        if strings.HasPrefix(request.Method, "__api_") {
            data, err = e.tapiCall(request.Method[6:], request.Params)
        } else {
            panic(errors.New(request.Method + " not support"))
        }
    }
    if err != nil {
        panic(err)
    }
    ret = map[string]interface{}{
        "data": data,
    }

    return
}

func main() {
    var addr = flag.String("b", "127.0.0.1:6666", "bind addr")
    flag.Parse()
    if *addr == "" {
        flag.Usage()
        return
    }
    basePath := "/exchange"
    log.Println("Running ", fmt.Sprintf("http://%s%s", *addr, basePath), "...")
    http.HandleFunc(basePath, OnPost)
    http.ListenAndServe(*addr, nil)
}


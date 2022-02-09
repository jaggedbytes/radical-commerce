import { List } from "antd";
import { useEventListener } from "eth-hooks/events/useEventListener";

import  Address from "./Address";

/**
  ~ What it does? ~

  Displays a lists of events

  ~ How can I use? ~

  <Events
    contracts={readContracts}
    contractName="YourContract"
    eventName="SetPurpose"
    localProvider={localProvider}
    mainnetProvider={mainnetProvider}
    startBlock={1}
  />
**/

export default function Events({ contracts, contractName, eventName, localProvider, mainnetProvider, startBlock }) {
  // 📟 Listen for broadcast events
  const events = useEventListener(contracts, contractName, eventName, localProvider, startBlock);

  return (
    <div style={{ width: 600, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
      <h2>Events:</h2>
      <List
        bordered
        dataSource={events}
        renderItem={item => {
          console.log(item);
          return (
            <List.Item key={item.blockNumber}>
              {item.args.taxpayerAddress} <br />
              {item.args.single ? "True" : "False"} <br />
              {item.args.salary.toNumber()} <br />
              {item.args.taxRate.toNumber()} <br />
              {item.args.taxBalance.toNumber()} <br />
              {item.args.taxable ? "True" : "False"} <br />
              {item.args.status}
            </List.Item>
          );
        }}
      />
    </div>
  );
}

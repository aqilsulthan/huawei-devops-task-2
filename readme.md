# DevOps Test Huawei - Task 2 Automation Testing

## Description

Automation script to collect system resource data (CPU, memory, disk) 3 times daily (08:00, 12:00, 15:00 WIB) to /home/cron with format `cron_DDMMYYYY_HH.MM.csv`. Automatically deletes CSV files older than 30 days with logging of deleted files.

## How to Run

#### Step 1: Use git to clone this project

```
git clone https://github.com/aqilsulthan/huawei-devops-task-2
```

#### Step 2: Navigate to the cloned directory and make the setup script executable and run it

```
cd huawei-devops-task-2
chmod +x task2_automation.sh
./task2_automation.sh
```

#### Step 3: Verify crontab entries
```
crontab -l
```

## Files

`task2_automation.sh`: Sets up automation.

`collect_data.py`: Collects system data to CSV.

`clean_data.sh`: Deletes CSV files more than 30 days, logs deleted files.

`collector.log`: Collection log (lists collected files)

`cleanup.log`: Cleanup log (lists deleted files)
